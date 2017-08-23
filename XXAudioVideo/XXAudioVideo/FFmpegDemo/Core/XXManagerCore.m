//
//  XXManagerCore.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/28.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "XXManagerCore.h"

@implementation XXManagerCore

+(instancetype)sharedInstance{
    static XXManagerCore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XXManagerCore alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init{
    if(self = [super init]){
        _remuxer = [[XXFFmpegRemuxer alloc] init];
        _decoder = [[XXFFmpegDecoder alloc] init];
    }
    return self;
}

@end
