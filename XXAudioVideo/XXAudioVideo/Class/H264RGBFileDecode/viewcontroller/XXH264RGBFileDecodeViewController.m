//
//  XXH264RGBFileDecodeViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/7.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXH264RGBFileDecodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXFileDecodeView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H264RGBDecoderImpl.h"
#import "XXRGBOpenGLView.h"
#include "pthread.h"

@interface XXH264RGBFileDecodeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,H264RGBDecoderImplDelegate,XXFileDecodeViewDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    H264RGBDecoderImpl *_h264Decoder;
    XXRGBOpenGLView *_playLayer;
    VideoFileParser *_fileParser;
}
@property (nonatomic,strong) NSThread  *encodeThread;
@property (assign, nonatomic) pthread_mutex_t lockThread;

@end

@implementation XXH264RGBFileDecodeViewController

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
    
    _playLayer = [[XXRGBOpenGLView alloc] initWithFrame:self.view.bounds];
    _playLayer.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playLayer];
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void) initData{
    if (!_h264Decoder) {
        _h264Decoder = [[H264RGBDecoderImpl alloc] initWithConfiguration];
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
    self.encodeThread.name = [NSString stringWithFormat:@"DecodeThread!"];
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
