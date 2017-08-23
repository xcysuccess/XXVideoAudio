//
//  LAScreenEx.h
//  LATestViewController
//
//  Created by tomxiang on 2017/6/6.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
    CGFloat getLAScreenIPhone6Width();
    CGFloat getLAScreenIPhone6Height();
    
    CGFloat getLAScreenWidth();
    CGFloat getLAScreenHeight();
    
    CGFloat fitLAScreenW(CGFloat value);
    CGFloat fitLAScreenH(CGFloat value);
    CGFloat fitLAScreenF(CGFloat value);
    
    CGFloat getLAImageWidthScale();
    CGFloat getLAImageHeightScale();
    
    BOOL isPortrait();
#ifdef __cplusplus
}
#endif

#define _adapt_W(value)    fitLAScreenW(value)
#define _adapt_H(value)    fitLAScreenH(value)
#define _adapt_F(value)    fitLAScreenF(value)
#define ISPORTRAIT         isPortrait()
#define IMAGESCALEWIDTH    getLAImageWidthScale()
#define IMAGESCALEHEIGHT   getLAImageHeightScale()
#define STATUS_HEIGHT      20.f

@interface LAScreenEx : NSObject

@end
