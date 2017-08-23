//
//  XXCameraViewController.m
//  XXCamara
//
//  Created by tomxiang on 20/10/2016.
//  Copyright © 2016 tomxiang. All rights reserved.
//

#import "XXH264FileDecodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXFileDecodeView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H264HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"
#include "pthread.h"

@interface XXH264FileDecodeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,H264HwDecoderImplDelegate,XXFileDecodeViewDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    H264HwDecoderImpl *_h264Decoder;
    AAPLEAGLLayer *_playLayer;
    VideoFileParser *_fileParser;
}
@property (nonatomic,strong) NSThread  *encodeThread;
@property (assign, nonatomic) pthread_mutex_t lockThread;

@end

@implementation XXH264FileDecodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initViews];
    [self initData];
}
-(void)dealloc{
    pthread_mutex_destroy(&_lockThread);
}

- (void) initViews{
    self.view.backgroundColor = [UIColor yellowColor];
    _beautyMenuView = [[XXFileDecodeView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_beautyMenuView];
    _beautyMenuView.delegate = self;
    [_beautyMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.bottom.equalTo(self.view);
        make.height.mas_equalTo(100);
    }];
    
    _playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.height- 40)];
    _playLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:_playLayer];
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void) initData{
    if (!_h264Decoder) {
        _h264Decoder = [[H264HwDecoderImpl alloc] initWithConfiguration];
        _h264Decoder.delegate = self;
    }
    pthread_mutex_init(&_lockThread, NULL);
    
}


#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        NSLog(@"testtest::tomxiangh264!");
        _playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

- (void)startDecodeButtonClick{
    if (self.encodeThread) {
        return;
    }
    
    NSString *h264FileSavePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"h264"];
    _fileParser = [VideoFileParser alloc];
    [_fileParser open:h264FileSavePath];
    
    //thread for tracking
    self.encodeThread = [[NSThread alloc] initWithTarget:self selector:@selector(trackingThreadWork) object:nil];
    self.encodeThread.name = [NSString stringWithFormat:@"EncodeThread!"];
    [self.encodeThread start];
}

-(void) trackingThreadWork{
    pthread_mutex_lock(&_lockThread);
    VideoPacket *vp = nil;
    while (self.encodeThread
           && ![NSThread currentThread].isCancelled){
        vp = [_fileParser nextPacket];
        if(vp == nil) {
            break;
        }
        [_h264Decoder decodeNalu:vp.buffer withSize:(unsigned int)vp.size];
    }
    pthread_mutex_unlock(&_lockThread);
}
- (void)stopDecodeButtonClick{
    if (self.encodeThread && [self.encodeThread isExecuting]) {
        [_h264Decoder stopDecoder];
        [self.encodeThread cancel];
        self.encodeThread = nil;
    }
}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
@end
