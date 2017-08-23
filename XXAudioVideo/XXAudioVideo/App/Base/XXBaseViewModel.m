//
//  XXBaseViewModel.m
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//

#import "XXBaseViewModel.h"

@interface XXBaseViewModel()
@end

@implementation XXBaseViewModel

-(instancetype)initWithFileName:(NSString*) fileName{
    if (self = [super init]) {
        [self initData:fileName];
        [self initOtherDataSource];
    }
    return self;
}

-(void)initData:(NSString*) fileName{
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];//@"SettingViewController"
    _listContentData = [[NSMutableArray alloc] initWithArray:[NSArray arrayWithContentsOfFile:path]];
}


-(NSUInteger) getModelGroupCount{
    return _listContentData.count;
}

-(NSDictionary*) getObjectAtIndex:(NSUInteger) section{
    return [_listContentData objectAtIndex:section];
}

-(void) initOtherDataSource{}

@end
