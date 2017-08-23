//
//  AACHwEncoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/21.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AACHwEncoderImpl : NSObject


@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer
            completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;

@end
