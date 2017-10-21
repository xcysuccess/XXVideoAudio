//
//  H265HwDecodeTool.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/10/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

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

@protocol H265FFmpegRGBDecoderImplDelegate <NSObject>
- (void)displayH265DecodedFrame:(CVImageBufferRef )imageBuffer;
@end

@interface H265HwDecodeTool : NSObject

@property (weak, nonatomic) id<H265FFmpegRGBDecoderImplDelegate> delegate;

-(void) setParameters:(AVCodecParameters*) parameters;

-(void) hwDecodePacket:(AVPacket*) avPacket;

@end
