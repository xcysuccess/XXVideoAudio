//
//  LAScreenEx.m
//  LATestViewController
//
//  Created by tomxiang on 2017/6/6.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "LAScreenEx.h"

#define VIEWWIDTH_UI_LANDSCAPE 667.f
#define VIEWHEIGHT_UI_LANDSCAPE 375.f

#define VIEWWIDTH_UI_PORTRAIT 375.f
#define VIEWHEIGHT_UI_PORTRAIT 667.f

@implementation LAScreenEx

BOOL isPortrait()
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPortrait = NO;
    if(orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown){
        isPortrait = YES;
    }
    return isPortrait;
}

CGFloat getLAScreenIPhone6Width()
{
    if(isPortrait()){
        return VIEWWIDTH_UI_PORTRAIT;
    }else{
        return VIEWWIDTH_UI_LANDSCAPE;
    }
}

CGFloat getLAScreenIPhone6Height()
{
    if(isPortrait()){
        return VIEWHEIGHT_UI_PORTRAIT;
    }else{
        return VIEWHEIGHT_UI_LANDSCAPE;
    }
}

CGFloat getLAScreenWidth()
{
    CGRect frame = [UIScreen mainScreen].bounds;
    if(isPortrait()){
        return MIN(frame.size.height, frame.size.width);
    }else{
        return MAX(frame.size.height, frame.size.width);
    }
}

CGFloat getLAScreenHeight()
{
    CGRect frame = [UIScreen mainScreen].bounds;
    if(isPortrait()){
        return MAX(frame.size.height, frame.size.width);
    }else{
        return MIN(frame.size.height, frame.size.width);
    }
}


//以iPhone6屏幕宽度为基准，小屏缩放
CGFloat fitLAScreenW(CGFloat value)
{
    return value * (getLAScreenWidth()/getLAScreenIPhone6Width());
}

//以iPhone6屏幕高度为基准
CGFloat fitLAScreenH(CGFloat value)
{
    return value * (getLAScreenHeight()/getLAScreenIPhone6Height());
}

//以iPhone6屏幕字体为基准
CGFloat fitLAScreenF(CGFloat value){
    return value * (getLAScreenWidth()/getLAScreenIPhone6Width());
}
CGFloat getLAImageWidthScale()
{
    return getLAScreenWidth()/getLAScreenIPhone6Width();
}

CGFloat getLAImageHeightScale()
{
    return getLAScreenHeight()/getLAScreenIPhone6Height();
}

@end
