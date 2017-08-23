//
//  OSMOBeautyMenuView.h
//  Phantom3
//
//  Created by tomxiang on 24/10/2016.
//  Copyright © 2016 DJIDevelopers.com. All rights reserved.
//

#import <UIKit/UIkit.h>

#define MANUALModeViewHeight 30
#define MANUALModeViewWidth  25

@protocol OSMOBeautyMenuViewDelegate <NSObject>

- (void)startEncodeButtonClick;
- (void)stopEncodeButtonClick;
- (void)closeVCClick;


@end

@interface OSMOBeautyMenuView : UIView
@property (weak, nonatomic) id<OSMOBeautyMenuViewDelegate> delegate;

@end
