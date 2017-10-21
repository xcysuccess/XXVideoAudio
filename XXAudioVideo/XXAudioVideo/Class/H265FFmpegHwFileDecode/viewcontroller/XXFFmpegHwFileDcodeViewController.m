//
//  XXH265FileDecodeViewController.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/8/22.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXFFmpegHwFileDcodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XXFileDecodeView.h"
#import "VideoFileParser.h"

#import "Masonry.h"
#import "LASessionSize.h"
#import "H265HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"
#import "FileFFmpegRemuxTool.h"


@interface XXFFmpegHwFileDcodeViewController()<AVCaptureVideoDataOutputSampleBufferDelegate,H265FFmpegRGBDecoderImplDelegate,XXFileDecodeViewDelegate>
{
    XXFileDecodeView   *_beautyMenuView;
    FileFFmpegRemuxTool *_fileFFmpegRemuxTool;
    AAPLEAGLLayer *_playLayer;
}

@end

@implementation XXFFmpegHwFileDcodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initViews];
    [self initData];
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
    
    _playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width - 40, self.view.frame.size.height- 40)];
    _playLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:_playLayer];
    
    [self.view bringSubviewToFront:_beautyMenuView];
}

- (void) initData{
    if (!_fileFFmpegRemuxTool) {
        _fileFFmpegRemuxTool = [[FileFFmpegRemuxTool alloc] init];
        _fileFFmpegRemuxTool.delegate = self;
    }    
}


#pragma mark -  H266解码回调  H265FFmpegRGBDecoderImplDelegate
- (void)displayH265DecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        CVPixelBufferRetain(imageBuffer);
        _playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

- (void)startDecodeButtonClick{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"h265_aac" ofType:@"mov"];
    [_fileFFmpegRemuxTool decoderFile:filePath];

}

- (void)stopDecodeButtonClick{

}

- (void)closeVCClick{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end
