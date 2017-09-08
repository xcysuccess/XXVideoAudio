//
//  H264RGBDecoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;




typedef enum{
    NALUTypeBPFrame = 0x01,
    NALUTypeIFrame = 0x05,
    NALUTypeSPS = 0x07,
    NALUTypePPS = 0x08
}NALUType;

@protocol H264RGBDecoderImplDelegate <NSObject>
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer;
@end

@interface H264RGBDecoderImpl : NSObject
@property (weak, nonatomic) id<H264RGBDecoderImplDelegate> delegate;

- (instancetype) initWithConfiguration;

- (void) stopDecoder;

-(void)decodeNalu:(uint8_t *)data withSize:(uint32_t)dataLen;
//-(void) decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;
@end
