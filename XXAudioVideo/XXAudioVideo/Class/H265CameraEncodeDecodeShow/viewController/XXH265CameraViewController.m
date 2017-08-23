//
//  XXH265CameraViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/6.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXH265CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "OSMOBeautyMenuView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H265HwEncoderImpl.h"
#import "AAPLEAGLLayer.h"

@interface XXH265CameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,H265HwEncoderImplDelegate,OSMOBeautyMenuViewDelegate>
{
    NSFileHandle *_fileHandle;
    NSString *_h265File;
    BOOL _isStartedEncoded;
    
    AVCaptureConnection  *_connection;
    AVCaptureDevice      *_videoDevice;
    AVCaptureSession     *_captureSession;
    OSMOBeautyMenuView   *_beautyMenuView;
    
    H265HwEncoderImpl *_h265Encoder;
    AVCaptureVideoPreviewLayer *_previewLayer;
}

@end

@implementation XXH265CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initViews];
    [self initData];
    [self startCaptureSession];
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
    if(!_h265Encoder){
        _h265Encoder = [[H265HwEncoderImpl alloc] initWithConfiguration];
        _h265Encoder.delegate = self;
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
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ){
            return device;
        }
    return nil;
}

- (void) startCaptureSession {
    NSError *error = nil;
    _videoDevice = [self p_cameraWithPosition:AVCaptureDevicePositionFront];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice
                                                                        error:&error];
    if (!input) {
        NSLog(@"PANIC: no media input");
    }
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [session addOutput:output];
    
    [session beginConfiguration];
    session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
    _connection = [output connectionWithMediaType:AVMediaTypeVideo];
    [self setRelativeVideoOrientation];
    [session commitConfiguration];
    [session startRunning];
    
    _captureSession = session;
    
    //view
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    _previewLayer.frame = CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.height- 40);
    _previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:_previewLayer];
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void)stopCaptureSession{
    [_captureSession stopRunning];
    [_previewLayer removeFromSuperlayer];
}

#pragma mark- disOutputSampleBuffer
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    [[LASessionSize sharedInstance] setWidth:(CGFloat)width height:(CGFloat)height];
    
    if(_isStartedEncoded == YES){
        [_h265Encoder encode:sampleBuffer];
    }
}

#pragma mark -  H264HwEncoderImplDelegate delegare

- (void)getVpsSpsPps:(NSData*)vps sps:(NSData*)sps pps:(NSData*)pps
{
    NSLog(@"getVpsSpsPps %d %d %d",(int)[vps length], (int)[sps length], (int)[pps length]);
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:vps];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:sps];
    [_fileHandle writeData:ByteHeader];
    [_fileHandle writeData:pps];
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
    }
}

#pragma mark- H264HwEncoderImplDelegate
-(void) startEncodeButtonClick{
    NSLog(@"%s",__func__);
    
    //设置时间输出格式：
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    _h265File = [documentsDirectory stringByAppendingPathComponent:@"test_tomxiang.h265"];
    
    [fileManager removeItemAtPath:_h265File error:nil];
    [fileManager createFileAtPath:_h265File contents:nil attributes:nil];
    
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_h265File];
    _isStartedEncoded = YES;
}

-(void) stopEncodeButtonClick{
    NSLog(@"%s",__func__);
    _isStartedEncoded = NO;
    [_h265Encoder stopEncoder];
    [_fileHandle closeFile];
    _fileHandle = NULL;
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
            _connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            _connection.videoOrientation =
            AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            _connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            _connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}

@end
