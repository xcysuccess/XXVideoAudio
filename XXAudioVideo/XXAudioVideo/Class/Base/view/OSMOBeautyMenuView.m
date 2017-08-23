//
//  OSMOBeautyMenuView.m
//  Phantom3
//
//  Created by tomxiang on 24/10/2016.
//  Copyright © 2016 DJIDevelopers.com. All rights reserved.
//

#import "OSMOBeautyMenuView.h"
#import "Masonry.h"

@interface OSMOBeautyMenuView()
@property(nonatomic,strong) UIButton *buttonStart;
@property(nonatomic,strong) UIButton *buttonStop;
@property(nonatomic,strong) UIButton *buttonStyleClose;
@end

@implementation OSMOBeautyMenuView

-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        [self initViews];
    }
    return self;
}


-(UILabel*) createLabel:(NSString*) textStr{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setFont:[UIFont systemFontOfSize:14.f]];
    label.adjustsFontSizeToFitWidth = YES;
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    label.text = textStr;
    [label setHidden:NO];
    [label setAlpha:1.0];
    return label;
}

-(UILabel*) createRedLabel:(NSString*) textStr{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    [label setFont:[UIFont systemFontOfSize:14.f]];
    label.adjustsFontSizeToFitWidth = YES;
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor redColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    label.text = textStr;
    [label setHidden:NO];
    [label setAlpha:1.0];
    return label;
}

-(UIButton*) createButton:(NSString*) textStr tag:(NSInteger) tag{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    button.tag = tag;
    button.backgroundColor = [UIColor redColor];
    button.layer.borderWidth = 1.f;
    button.layer.borderColor = [UIColor yellowColor].CGColor;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    [button setTitle:textStr forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = [UIFont systemFontOfSize:12];
    return button;
}

-(void) initViews{
  
    self.buttonStart = [self createButton:@"StartEncode" tag:1];
    self.buttonStop = [self createButton:@"StopEncode" tag:2];
    self.buttonStyleClose = [self createButton:@"Close" tag:3];
    
    [self addSubview:_buttonStart];
    [self addSubview:_buttonStop];
    [self addSubview:_buttonStyleClose];
    
    [self setMasoryAutoLayout];
}

- (void)buttonClick:(UIButton *)aBt
{
    switch(aBt.tag){
        case 1:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(startEncodeButtonClick)]) {
                [self.delegate startEncodeButtonClick];
            }
        }
            break;
        case 2:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(stopEncodeButtonClick)]) {
                [self.delegate stopEncodeButtonClick];
            }
        }
            break;
        case 3:{
            if (self.delegate && [self.delegate respondsToSelector:@selector(closeVCClick)]) {
                [self.delegate closeVCClick];
            }
        }
    }
}


-(void) setMasoryAutoLayout{
    
    //----button ---
    [self.buttonStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self).multipliedBy(0.23);
        make.height.mas_equalTo(MANUALModeViewHeight);
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(0);
    }];
    
    [self.buttonStop mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self).multipliedBy(0.23);
        make.height.mas_equalTo(MANUALModeViewHeight);
        make.left.equalTo(self.buttonStart.mas_right).offset(10);
        make.top.mas_equalTo(0);
    }];
    
    [self.buttonStyleClose mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self).multipliedBy(0.23);
        make.height.mas_equalTo(MANUALModeViewHeight);
        make.right.equalTo(self.mas_right).offset(-10);
        make.top.mas_equalTo(0);
    }];
}
@end
