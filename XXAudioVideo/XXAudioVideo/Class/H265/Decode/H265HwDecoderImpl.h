//
//  H265HwDecoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

//http://www.jianshu.com/p/00a2ed58a77b
typedef enum{
    NAL_TRAIL_N    = 0,
    NAL_TRAIL_R    = 1,
    NAL_TSA_N      = 2,
    NAL_TSA_R      = 3,
    NAL_STSA_N     = 4,
    NAL_STSA_R     = 5,
    NAL_RADL_N     = 6,
    NAL_RADL_R     = 7,
    NAL_RASL_N     = 8,
    NAL_RASL_R     = 9,
    NAL_BLA_W_LP   = 16,
    NAL_BLA_W_RADL = 17,
    NAL_BLA_N_LP   = 18,
    NAL_IDR_W_RADL = 19,
    NAL_IDR_N_LP   = 20,
    NAL_CRA_NUT    = 21,
    NAL_VPS        = 32,
    NAL_SPS        = 33,
    NAL_PPS        = 34,
    NAL_AUD        = 35,
    NAL_EOS_NUT    = 36,
    NAL_EOB_NUT    = 37,
    NAL_FD_NUT     = 38,
    NAL_SEI_PREFIX = 39,
    NAL_SEI_SUFFIX = 40,
}NALUType265;

@protocol H265HwDecoderImplDelegate <NSObject>
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer;
@end

@interface H265HwDecoderImpl : NSObject
@property (weak, nonatomic) id<H265HwDecoderImplDelegate> delegate;

- (instancetype) initWithConfiguration;

- (void) stopDecoder;

-(void)decodeNalu:(uint8_t *)data withSize:(uint32_t)dataLen;
//-(void) decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;
@end
