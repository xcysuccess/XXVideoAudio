//
//  XXH265RGBFileDecodeViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/15.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXH265RGBFileDecodeViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "XXFileDecodeView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H265RGBDecoderImpl.h"
#import "XXRGBOpenGLView.h"
#include "pthread.h"
#import "XXImageTool.h"

#define USE_SYSTEM_SHOWSCREEN (1)

@interface XXH265RGBFileDecodeViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,H265RGBHwDecoderImplDelegate,XXFileDecodeViewDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    H265RGBDecoderImpl *_h265RGBDecoder;
    XXRGBOpenGLView *_playLayer;
    VideoFileParser *_fileParser;
#if USE_SYSTEM_SHOWSCREEN
    UIImageView *_displayImageView;
#endif
}
@property (nonatomic,strong) NSThread  *encodeThread;
@property (assign, nonatomic) pthread_mutex_t lockThread;

@end

@implementation XXH265RGBFileDecodeViewController

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

#if USE_SYSTEM_SHOWSCREEN
    _displayImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _displayImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_displayImageView];
#endif
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void) initData{
    if (!_h265RGBDecoder) {
        _h265RGBDecoder = [[H265RGBDecoderImpl alloc] initWithConfiguration];
        _h265RGBDecoder.delegate = self;
    }
    pthread_mutex_init(&_lockThread, NULL);
    
}


#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
#if USE_SYSTEM_SHOWSCREEN

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    UIImage *image= [UIImage imageWithCIImage:ciImage];//:newImage scale:1.0  orientation:UIImageOrientationRight];
    dispatch_async(dispatch_get_main_queue(), ^{
        _displayImageView.image = image;
    });
    CVPixelBufferRelease(imageBuffer);
#else
    if(imageBuffer)
    {
        NSLog(@"testtest::tomxiangh265!");
        _playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
#endif
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        [XXImageTool writePixelBufferToLocalFile:imageBuffer];
//    });
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
        [_h265RGBDecoder decodeNalu:vp.buffer withSize:(unsigned int)vp.size];
    }
    pthread_mutex_unlock(&_lockThread);
}
- (void)stopDecodeButtonClick{
    if (self.encodeThread && [self.encodeThread isExecuting]) {
        [_h265RGBDecoder stopDecoder];
        [self.encodeThread cancel];
        self.encodeThread = nil;
    }
}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
