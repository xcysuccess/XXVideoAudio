//
//  XXBaseTableCell.m
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//  

#import "XXBaseTableCell.h"
#import "XXGlobalColor.h"
#import "UITableViewCell+Custom.h"
#import "UIScreenEx.h"

@interface XXBaseTableCell()
@property(nonatomic,weak) id<BaseTableCellDelegate> delegate;
@end

@implementation XXBaseTableCell

-(nonnull instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nonnull NSString *)reuseIdentifier indexPath:(nonnull NSIndexPath*) indexPath
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.textLabel.font = [UIFont boldSystemFontOfSize:FontScreenSize];
        self.textLabel.textColor = QQGLOBAL_COLOR(kTableViewCellTextLabelTextColorNormal);
        self.textLabel.highlightedTextColor = QQGLOBAL_COLOR(kTableViewCellTextLabelTextColorHighlighted);
        
        self.userInteractionEnabled = YES;
        
        
    }
    return self;
}

-(void) configureData:(NSString*) tipText imageKey:(NSString*) imageKey
{
    [self setCustomAccessoryViewEnabled:YES];
    
    self.textLabel.text = tipText;
    if(imageKey.length > 0){
        self.imageView.image = [UIImage imageNamed:imageKey];
    }
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
}

-(void) configureDataWithUISwtich:(BOOL) isOn tipText:(NSString*) tipText delegate:(id<BaseTableCellDelegate>) delegate
{
    [self setCustomAccessoryViewEnabled:NO];
    
    self.delegate = delegate;
    
    UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:mySwitch];
    self.accessoryView = mySwitch;
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [mySwitch setOn:isOn];
    [mySwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    self.textLabel.text = tipText;
}


-(void)switchAction:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;
    BOOL isButtonOn = [switchButton isOn];
    
    if([self.delegate respondsToSelector:@selector(switchAction:)]){
        [self.delegate switchAction:isButtonOn];
    }
}

@end
