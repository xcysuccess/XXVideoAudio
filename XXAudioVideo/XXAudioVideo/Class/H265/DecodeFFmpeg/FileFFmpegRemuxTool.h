//
//  H265FFmpegRGBDecoderImpl.h
//  XXAudioVideo
//
//  Created by tomxiang on 2017/9/30.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "H265HwDecodeTool.h"

@import AVFoundation;

@interface FileFFmpegRemuxTool : NSObject

@property (weak, nonatomic) id<H265FFmpegRGBDecoderImplDelegate> delegate;

-(void) decoderFile:(NSString*) filePath;

@end
