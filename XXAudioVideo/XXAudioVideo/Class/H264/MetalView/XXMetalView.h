//
//  XXMetalView.h
//  XXAudioVideo
//
//  Created by tomxiang on 2018/12/26.
//  Copyright © 2018年 tomxiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface XXMetalView : UIView

@property CVPixelBufferRef pixelBuffer;


@end

NS_ASSUME_NONNULL_END
