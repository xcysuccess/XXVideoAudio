//
//  XXBaseViewModel.h
//  XXKit
//
//  Created by tomxiang on 16/3/9.
//  Copyright © 2016年 tomxiang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ITEM_CONTENT @"itemContent"
#define ITEM_KEY     @"itemKey"
#define ITEM_ACCOUNT @"itemAccount"
#define ITEM_VALUE   @"itemValue"
#define ITEM_IMAGE   @"itemImage"

@interface XXBaseViewModel : NSObject
{
@protected
    NSMutableArray *_listContentData;
}


-(instancetype)initWithFileName:(NSString*) fileName;

//获取模型分组总数据
-(NSUInteger) getModelGroupCount;

//获取每一组的数据
-(NSDictionary*) getObjectAtIndex:(NSUInteger) section;

@end
