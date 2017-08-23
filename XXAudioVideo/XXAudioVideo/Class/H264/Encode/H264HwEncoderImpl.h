//
//  H264HwEncoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/27.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

@protocol H264HwEncoderImplDelegate <NSObject>

- (void)getSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)getEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface H264HwEncoderImpl : NSObject

- (instancetype) initWithConfiguration;

- (void) encode:(CMSampleBufferRef )sampleBuffer;

- (void) stopEncoder;

@property (weak, nonatomic) id<H264HwEncoderImplDelegate> delegate;

@end
