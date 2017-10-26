//
//  AACDecodeTool.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/imgutils.h"
#include "libavutil/avstring.h"
#include "libswscale/swscale.h"
    
#ifdef __cplusplus
};
#endif

@interface AACPlayer : NSObject


-(void) setParameters:(AVCodecParameters*) parameters;

-(void) hwDecodePacket:(AVPacket*) avPacket;


@end
