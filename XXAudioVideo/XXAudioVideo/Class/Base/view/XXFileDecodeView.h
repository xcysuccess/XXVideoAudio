//
//  XXFileDecodeView.h
//  Phantom3
//
//  Created by tomxiang on 24/10/2016.
//  Copyright © 2016 DJIDevelopers.com. All rights reserved.
//

#import <UIKit/UIkit.h>

#define MANUALModeViewHeight 30
#define MANUALModeViewWidth  25

@protocol XXFileDecodeViewDelegate <NSObject>

- (void)startDecodeButtonClick;
- (void)stopDecodeButtonClick;
- (void)closeVCClick;

@end

@interface XXFileDecodeView : UIView
@property (weak, nonatomic) id<XXFileDecodeViewDelegate> delegate;
@property (readonly, nonatomic,strong) UIButton *buttonStart;
@property (readonly, nonatomic,strong) UIButton *buttonStop;
@property (readonly, nonatomic,strong) UIButton *buttonStyleClose;

@end
