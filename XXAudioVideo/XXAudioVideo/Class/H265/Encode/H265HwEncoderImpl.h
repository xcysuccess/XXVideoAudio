//
//  H265HwEncoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/6.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;

@protocol H265HwEncoderImplDelegate <NSObject>

- (void)getVpsSpsPps:(NSData*)vps sps:(NSData*)sps pps:(NSData*)pps;
- (void)getEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface H265HwEncoderImpl : NSObject
- (instancetype) initWithConfiguration;

- (void) encode:(CMSampleBufferRef )sampleBuffer;

- (void) stopEncoder;

@property (weak, nonatomic) id<H265HwEncoderImplDelegate> delegate;
@end
