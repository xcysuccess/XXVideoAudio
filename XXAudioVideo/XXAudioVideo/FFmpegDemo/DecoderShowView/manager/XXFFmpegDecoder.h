//
//  XXFFmpegDecoder.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/8/16.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>


@protocol XXFFmpegDecoderImplDelegate <NSObject>
- (void)setVideoSize:(GLuint)width height:(GLuint)height;
- (void)displayYUV420pData:(void *)data width:(NSInteger)w height:(NSInteger)h;
@end

@interface XXFFmpegDecoder : NSObject

@property(nonatomic,weak) id<XXFFmpegDecoderImplDelegate> delegate;

-(void) decoderFile:(NSString*) filePath;

@end
