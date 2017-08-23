//
//  XXCameraViewController.m
//  XXCamara
//
//  Created by tomxiang on 20/10/2016.
//  Copyright © 2016 tomxiang. All rights reserved.
//

#import "XXCameraHardEncodeDecodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "OSMOBeautyMenuView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H264HwEncoderImpl.h"
#import "H264HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"
#import "AACHwEncoderImpl.h"

@interface XXCameraHardEncodeDecodeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate,H264HwDecoderImplDelegate,OSMOBeautyMenuViewDelegate>
{
    NSFileHandle *_fileHandle;
    NSString *_h264File;
    
    NSFileHandle *_audioFileHandle;
    NSString *_aacFile;
    
    BOOL _isStartedEncoded;

    OSMOBeautyMenuView   *_beautyMenuView;
    
    H264HwEncoderImpl *_h264Encoder;
    H264HwDecoderImpl *_h264Decoder;
    
    AACHwEncoderImpl *_aacEncoder;
    
    AAPLEAGLLayer *_playLayer;
}
@property (nonatomic , strong) AVCaptureSession *captureSession; //负责输入和输出设备之间的数据传递

@property (nonatomic , strong) AVCaptureConnection *videoConnection;
@property (nonatomic , strong) AVCaptureConnection *audioConnection;

@property (nonatomic , strong) AVCaptureAudioDataOutput *captureAudioOutput;
@property (nonatomic , strong) AVCaptureVideoDataOutput *captureVideoOutput;

@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

@property (nonatomic , strong) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation XXCameraHardEncodeDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
    
    [self initViews];
    [self initData];
    [self startCaptureSession];
    [self showPlayer];
}

-(void)dealloc{
}

- (void) enterBackground{
//    [self.dataSource sync];
}

- (void) initData{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    if(!_h264Encoder){
        _h264Encoder = [[H264HwEncoderImpl alloc] initWithConfiguration];
        _h264Encoder.delegate = self;
    }
    if (!_h264Decoder) {
        _h264Decoder = [[H264HwDecoderImpl alloc] initWithConfiguration];
        _h264Decoder.delegate = self;
    }
    if(!_aacEncoder){
        _aacEncoder = [[AACHwEncoderImpl alloc] init];
    }

}

- (void) initViews{
    self.view.backgroundColor = [UIColor yellowColor];
    _beautyMenuView = [[OSMOBeautyMenuView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_beautyMenuView];
    _beautyMenuView.delegate = self;
    [_beautyMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.bottom.equalTo(self.view);
        make.height.mas_equalTo(100);
    }];
}

- (AVCaptureDevice *)p_cameraWithPosition:(AVCaptureDevicePosition)position{
    AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession
                                                     discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                     mediaType:AVMediaTypeVideo
                                                     position:position];
    
    NSArray *devicesIOS  = devicesIOS10.devices;
    for (AVCaptureDevice *device in devicesIOS) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void) startCaptureSession {
    // 初始化 session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // 配置采集输入源（摄像头）
    NSError *error = nil;
    // 获得一个采集设备, 默认后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    // 用设备初始化一个采集的输入对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting  input device: %@", error.description);
        return;
    }
    
    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput]; // 添加到Session
    }
    if ([_captureSession canAddInput:audioInput]) {
        [_captureSession addInput:audioInput]; // 添加到Session
    }
    // 配置采集输出，即我们取得视频图像的接口
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    _captureVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _captureAudioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    [_captureVideoOutput setSampleBufferDelegate:self queue:_videoQueue];
    [_captureAudioOutput setSampleBufferDelegate:self queue:_audioQueue];
    
    // 配置输出视频图像格式
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    _captureVideoOutput.videoSettings = captureSettings;
    _captureVideoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_captureSession canAddOutput:_captureVideoOutput]) {
        [_captureSession addOutput:_captureVideoOutput];  // 添加到Session
    }
    
    if ([_captureSession canAddOutput:_captureAudioOutput]) {
//        [_captureSession addOutput:_captureAudioOutput]; // 添加到Session
    }
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源（Video/Audio）
    _videoConnection = [_captureVideoOutput connectionWithMediaType:AVMediaTypeVideo];
    _audioConnection = [_captureAudioOutput connectionWithMediaType:AVMediaTypeAudio];
    [self setRelativeVideoOrientation];
    [_captureSession startRunning];
}

- (void)showPlayer {
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    _previewLayer.frame = CGRectMake(0, 120, 160, 300);
    _previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:_previewLayer];
    
    _playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 160, 120, 160, 300)];
    _playLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:_playLayer];
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void)stopCaptureSession{
    [_captureSession stopRunning];
    [_previewLayer removeFromSuperlayer];
    [_playLayer removeFromSuperlayer];
}

#pragma mark- disOutputSampleBuffer
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    [[LASessionSize sharedInstance] setWidth:(CGFloat)width height:(CGFloat)height];
    
    if(_isStartedEncoded == YES){
        if (connection == self.videoConnection && self.captureVideoOutput == captureOutput) {
            [_h264Encoder encode:sampleBuffer];
        }
        else {
            [_aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
                [_audioFileHandle writeData:encodedData];
            }];
        }
    }
}

#pragma mark -  H264HwEncoderImplDelegate delegare

- (void)getSpsPps:(NSData*)sps pps:(NSData*)pps
{
    NSLog(@"getSpsPps %d %d", (int)[sps length], (int)[pps length]);

    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:sps];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:pps];

    //--h264 decode sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [_h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];

    //--h264 decode pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [_h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}

- (void)getEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    if (_fileHandle != NULL)
    {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        [_fileHandle writeData:ByteHeader];
        [_fileHandle writeData:data];
    
        //--h264 decode data
        NSMutableData *h264Data = [[NSMutableData alloc] init];
        [h264Data appendData:ByteHeader];
        [h264Data appendData:data];
        [_h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
    }
}

#pragma mark- H264HwEncoderImplDelegate
-(void) startEncodeButtonClick{
    NSLog(@"%s",__func__);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    _h264File = [documentsDirectory stringByAppendingPathComponent:@"test_tomxiang.h264"];
    [fileManager removeItemAtPath:_h264File error:nil];
    [fileManager createFileAtPath:_h264File contents:nil attributes:nil];
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_h264File];
    
    _aacFile = [documentsDirectory stringByAppendingPathComponent:@"test_tomxiang.aac"];
    [fileManager removeItemAtPath:_aacFile error:nil];
    [fileManager createFileAtPath:_aacFile contents:nil attributes:nil];
    _audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:_aacFile];
    
    _isStartedEncoded = YES;
}

-(void) stopEncodeButtonClick{
    NSLog(@"%s",__func__);
    _isStartedEncoded = NO;
    [_h264Encoder stopEncoder];
    [_h264Decoder stopDecoder];
    
    [_fileHandle closeFile];
    _fileHandle = NULL;
    
    [_audioFileHandle closeFile];
    _audioFileHandle = NULL;
}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (void)setRelativeVideoOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            _videoConnection.videoOrientation =
            AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}

#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        _playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

@end
