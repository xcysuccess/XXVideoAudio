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

typedef struct
{
    int write_adts;
    int objecttype;
    int sample_rate_index;
    int channel_conf;
}ADTSContext;

NS_INLINE int aac_decode_extradata(ADTSContext *adts, unsigned char *pbuf, int bufsize)
{
    int aot, aotext, samfreindex;
    int channelconfig;
    unsigned char *p = pbuf;
    
    if (!adts || !pbuf || bufsize<2)
    {
        return -1;
    }
    aot = (p[0]>>3)&0x1f;
    if (aot == 31)
    {
        aotext = (p[0]<<3 | (p[1]>>5)) & 0x3f;
        aot = 32 + aotext;
        samfreindex = (p[1]>>1) & 0x0f;
        
        if (samfreindex == 0x0f)
        {
            channelconfig = ((p[4]<<3) | (p[5]>>5)) & 0x0f;
        }
        else
        {
            channelconfig = ((p[1]<<3)|(p[2]>>5)) & 0x0f;
        }
    }
    else
    {
        samfreindex = ((p[0]<<1)|p[1]>>7) & 0x0f;
        if (samfreindex == 0x0f)
        {
            channelconfig = (p[4]>>3) & 0x0f;
        }
        else
        {
            channelconfig = (p[1]>>3) & 0x0f;
        }
    }
    
#ifdef AOT_PROFILE_CTRL
    if (aot < 2) aot = 2;
#endif
    adts->objecttype = aot-1;
    adts->sample_rate_index = samfreindex;
    adts->channel_conf = channelconfig;
    adts->write_adts = 1;
    
    return 0;
}


@interface AACPlayer : NSObject

-(void) setParameters:(AVCodecParameters*) parameters;

-(void) hwDecodePacket:(AVPacket*) avPacket;

@end
