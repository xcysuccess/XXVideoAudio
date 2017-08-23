//
//  VideoFileParse.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/3.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NALUnit: NSObject
@property(assign,nonatomic) unsigned int type;
@property(assign,nonatomic) unsigned char *data;
@property(assign,nonatomic) unsigned int size;
@end

@interface VideoPacket : NSObject

@property uint8_t* buffer;
@property NSInteger size;

@end

@interface VideoFileParser : NSObject

-(BOOL)open:(NSString*)fileName;
-(VideoPacket *)nextPacket;
-(void)close;

@end
