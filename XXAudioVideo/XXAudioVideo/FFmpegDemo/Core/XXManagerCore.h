//
//  XXManagerCore.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/28.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXFFmpegRemuxer.h"
#import "XXFFmpegDecoder.h"

@interface XXManagerCore : NSObject

+(instancetype)sharedInstance;

@property(nonatomic,strong) XXFFmpegRemuxer *remuxer;

@property(nonatomic,strong) XXFFmpegDecoder *decoder;


@end
