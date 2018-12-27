//
//  H265DecodeModel.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/12/4.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

@interface H265DecodeModel : NSObject

@property(nonatomic) CVImageBufferRef pixelBuffer;
@property(nonatomic,assign) CGFloat pts;

@end
