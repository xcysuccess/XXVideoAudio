//
//  XXH265FileDecodeViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/8/22.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXH265FileDecodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXFileDecodeView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H265HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"
#include "pthread.h"


@interface XXH265FileDecodeViewController()<AVCaptureVideoDataOutputSampleBufferDelegate,H265HwDecoderImplDelegate,XXFileDecodeViewDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    H265HwDecoderImpl *_h265Decoder;
    AAPLEAGLLayer *_playLayer;
    VideoFileParser *_fileParser;
}
@property (nonatomic,strong) NSThread  *encodeThread;
@property (assign, nonatomic) pthread_mutex_t lockThread;
@end

@implementation XXH265FileDecodeViewController

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
    if (!_h265Decoder) {
        _h265Decoder = [[H265HwDecoderImpl alloc] initWithConfiguration];
        _h265Decoder.delegate = self;
    }
    pthread_mutex_init(&_lockThread, NULL);
    
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

- (void)startDecodeButtonClick{
    if (self.encodeThread) {
        return;
    }
    
    NSString *h265FileSavePath = [[NSBundle mainBundle] pathForResource:@"testh265" ofType:@"hevc"];
    _fileParser = [VideoFileParser alloc];
    [_fileParser open:h265FileSavePath];
    
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
        [_h265Decoder decodeNalu:vp.buffer withSize:(unsigned int)vp.size];
    }
    pthread_mutex_unlock(&_lockThread);
}
- (void)stopDecodeButtonClick{
    if (self.encodeThread && [self.encodeThread isExecuting]) {
        [_h265Decoder stopDecoder];
        [self.encodeThread cancel];
        self.encodeThread = nil;
    }
}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
