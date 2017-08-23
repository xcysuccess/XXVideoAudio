//
//  LALiveConfiguration.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/6.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "LALiveConfiguration.h"


@implementation LALiveConfiguration

#pragma mark -- LifeCycle
+ (instancetype)defaultConfiguration{
    LALiveConfiguration *configuration = [LALiveConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_Default];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality{
    LALiveConfiguration *configuration = [LALiveConfiguration defaultConfigurationForQuality:videoQuality orientation:UIInterfaceOrientationPortrait];
    return configuration;
}

+ (instancetype)defaultConfigurationForQuality:(LFLiveVideoQuality)videoQuality orientation:(UIInterfaceOrientation)orientation{
    LALiveConfiguration *configuration = [LALiveConfiguration new];
    switch (videoQuality) {
        case LFLiveVideoQuality_Low1:
        {
            configuration.sessionPreset = LFCaptureSessionPreset368x640;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 500 * 1024;
            configuration.videoMaxBitRate = 600 * 1024;
            configuration.videoMinBitRate = 250 * 1024;
        }
            break;
        case LFLiveVideoQuality_Low2:
        {
            configuration.sessionPreset = LFCaptureSessionPreset368x640;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_Low3:
        {
            configuration.sessionPreset = LFCaptureSessionPreset368x640;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_Medium1:
        {
            configuration.sessionPreset = LFCaptureSessionPreset540x960;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_Medium2:
        {
            configuration.sessionPreset = LFCaptureSessionPreset540x960;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 800 * 1024;
            configuration.videoMaxBitRate = 900 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_Medium3:
        {
            configuration.sessionPreset = LFCaptureSessionPreset540x960;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_High1:
        {
            configuration.sessionPreset = LFCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 15;
            configuration.videoMaxFrameRate = 15;
            configuration.videoMinFrameRate = 10;
            configuration.videoBitRate = 1000 * 1024;
            configuration.videoMaxBitRate = 1200 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        case LFLiveVideoQuality_High2:
        {
            configuration.sessionPreset = LFCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 24;
            configuration.videoMaxFrameRate = 24;
            configuration.videoMinFrameRate = 12;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 800 * 1024;
        }
            break;
        case LFLiveVideoQuality_High3:
        {
            configuration.sessionPreset = LFCaptureSessionPreset720x1280;
            configuration.videoFrameRate = 30;
            configuration.videoMaxFrameRate = 30;
            configuration.videoMinFrameRate = 15;
            configuration.videoBitRate = 1200 * 1024;
            configuration.videoMaxBitRate = 1300 * 1024;
            configuration.videoMinBitRate = 500 * 1024;
        }
            break;
        default:
            break;
    }
    
    configuration.videoMaxKeyframeInterval = configuration.videoFrameRate*2;
    configuration.orientation = orientation;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        configuration.videoSize = CGSizeMake(368, 640);
    }else{
        configuration.videoSize = CGSizeMake(640, 368);
    }
    return configuration;
}

@end
