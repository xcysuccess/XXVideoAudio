//
//  XXBaseViewController.h
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXViewController.h"
@class XXBaseViewModel;

@protocol XXBaseVCRequireMethod <NSObject>
@required
-(NSString*) getViewModelFileName;
@end

@interface XXBaseViewController : XXViewController<XXBaseVCRequireMethod>

@property(nonatomic,strong) UITableView *baseTableView;
@property(nonatomic,strong) XXBaseViewModel *baseViewModel;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@end
