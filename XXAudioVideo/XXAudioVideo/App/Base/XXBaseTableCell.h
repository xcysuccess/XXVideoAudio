//
//  XXBaseTableCell.h
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BASECELLIDENDIFIFY @"BASE_CELL_IDENDIFIFY"


@protocol BaseTableCellDelegate <NSObject>
-(void) switchAction : (BOOL) isOn;
@end


@interface XXBaseTableCell : UITableViewCell

-(void) configureData:(NSString*) tipText imageKey:(NSString*) imageKey;

-(void) configureDataWithUISwtich:(BOOL) isOn tipText:(NSString*) tipText delegate:(id<BaseTableCellDelegate>) delegate;

@end
