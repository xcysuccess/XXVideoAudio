//
//  XXFFmpegDecoderViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/8/19.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXFFmpegDecoderViewController.h"
#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
    
#ifdef __cplusplus
};
#endif

#import "XXFileDecodeView.h"
#import "Masonry.h"
#import "XXManagerCore.h"
#import "AAPLEAGLLayer.h"
#include "pthread.h"
#import "OpenGLView20.h"

@interface XXFFmpegDecoderViewController ()<XXFileDecodeViewDelegate,XXFFmpegDecoderImplDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    OpenGLView20 *_openGLView;

}
@end

@implementation XXFFmpegDecoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initViews];
}
-(void)dealloc{
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
    
    _openGLView = [[OpenGLView20 alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.height- 140)];
    _openGLView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_openGLView];
}


#pragma mark- XXFileDecodeViewDelegate
- (void)startDecodeButtonClick{
//    sintel.mov
    NSString *moveString = [[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"];
    [XXManagerCore sharedInstance].decoder.delegate = self;
    [[XXManagerCore sharedInstance].decoder decoderFile:moveString];
}

- (void)stopDecodeButtonClick{
}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
 - (void)setVideoSize:(GLuint)width height:(GLuint)height{
     [_openGLView setVideoSize:width height:height];

 }
 - (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h{
     [_openGLView displayYUV420pData:data width:w height:h];
 }
@end
