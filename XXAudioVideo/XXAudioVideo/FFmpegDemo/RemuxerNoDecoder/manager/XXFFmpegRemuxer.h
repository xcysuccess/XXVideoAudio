//
//  XXFFmpegRemuxer.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/28.
//  Copyright © 2017年 tomxiang. All rights reserved.
//  http://blog.csdn.net/leixiaohua1020/article/details/25422685
//  http://blog.csdn.net/biezhihua/article/details/70835069

#import <Foundation/Foundation.h>

@interface XXFFmpegRemuxer : NSObject

//[[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"];
-(void) movToFlv:(NSString*) filePath;

@end
