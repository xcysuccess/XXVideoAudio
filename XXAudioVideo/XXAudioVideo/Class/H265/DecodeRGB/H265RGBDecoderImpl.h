//
//  H265RGBDecoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/15.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

@protocol H265RGBHwDecoderImplDelegate <NSObject>
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer;
@end
@interface H265RGBDecoderImpl : NSObject

@property (weak, nonatomic) id<H265RGBHwDecoderImplDelegate> delegate;

- (instancetype) initWithConfiguration;

- (void) stopDecoder;

-(void)decodeNalu:(uint8_t *)data withSize:(uint32_t)dataLen;
//-(void) decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize;

@end
