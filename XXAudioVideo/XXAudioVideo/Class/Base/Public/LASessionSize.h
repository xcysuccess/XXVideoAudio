//
//  LASessionSize.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/7/2.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreGraphics;

@interface LASessionSize : NSObject

+(instancetype) sharedInstance;

@property(nonatomic,assign,readonly) CGFloat h264outputWidth;
@property(nonatomic,assign,readonly) CGFloat h264outputHeight;

-(void) setWidth:(CGFloat) width height:(CGFloat) height;

@end
