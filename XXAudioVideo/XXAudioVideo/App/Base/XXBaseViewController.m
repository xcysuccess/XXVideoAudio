//
//  XXBaseViewController.m
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//

#import "XXBaseViewController.h"
#import "XXBase.h"
#import "UITableView+Global.h"
#import "UITableViewCell+Custom.h"
#import "XXBaseTableCell.h"
#import "XXBaseViewModel.h"

@interface XXBaseViewController ()<UITableViewDelegate,UITableViewDataSource>
@end

@implementation XXBaseViewController

-(instancetype)init
{
    if (self = [super init]) {
        self.baseViewModel = [[XXBaseViewModel alloc] initWithFileName:[self getViewModelFileName]];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*) getViewModelFileName{
    assert(0);
    return nil;
}

-(void)loadView
{
    [super loadView];
    
    _baseTableView = [UITableView commonGroupStyledTableView:self dataSource:self frame:self.view.bounds];
    [_baseTableView registerClass:[XXBaseTableCell class] forCellReuseIdentifier:BASECELLIDENDIFIFY];
    
    [self.view addSubview:_baseTableView];
}

#pragma mark- Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _size_H_6(44);
}


- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return _size_H_6(20.f);;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == [tableView numberOfSections] - 1) {
        return _size_H_6(20);
    }  else {
        return _size_H_6(0.01);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark- DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;              // Default is 1 if not implemented
{
    return [_baseViewModel getModelGroupCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary * dict = [_baseViewModel getObjectAtIndex:section];
    NSArray * array = [dict objectForKey:ITEM_CONTENT];
    
    return [array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    
    XXBaseTableCell *cell = [tableView dequeueReusableCellWithIdentifier:BASECELLIDENDIFIFY forIndexPath:indexPath];
    if (cell == nil) {
        cell = (XXBaseTableCell*)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:BASECELLIDENDIFIFY];
    }
    
    NSDictionary * dict = [_baseViewModel getObjectAtIndex:section];
    NSArray * array = [dict objectForKey:ITEM_CONTENT];
    NSDictionary * dictObject = [array objectAtIndex:row];
    NSString * value = [dictObject objectForKey:ITEM_VALUE];
    NSString * imageKey = [dictObject objectForKey:ITEM_IMAGE];
    
    [cell configureData:value imageKey:imageKey];
    [cell updateBackgroundViewInTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

@end
