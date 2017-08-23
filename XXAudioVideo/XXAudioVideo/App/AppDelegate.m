//
//  AppDelegate.m
//  XXAudioVideo
//
//  Created by tomxiang on 2017/6/26.
//  Copyright © 2017年 tomxiang. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (){
    NSInteger count;
}
@property(strong, nonatomic)NSTimer *mTimer;
@property(assign, nonatomic)UIBackgroundTaskIdentifier backIden;

@end
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    count=0;
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _mTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_mTimer forMode:NSRunLoopCommonModes];
    [self beginTask];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"进入前台");
    [self endBack];
}

//计时
-(void)countAction{
    NSLog(@"%li",count++);
}

//申请后台
-(void)beginTask
{
    NSLog(@"begin=============");
    _backIden = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //在时间到之前会进入这个block，一般是iOS7及以上是3分钟。按照规范，在这里要手动结束后台，你不写也是会结束的（据说会crash）
        NSLog(@"将要挂起=============");
        [self endBack];
    }];
}

//注销后台
-(void)endBack
{
    NSLog(@"end=============");
    [_mTimer invalidate];
    _mTimer = nil;
    
    [[UIApplication sharedApplication] endBackgroundTask:_backIden];
    _backIden = UIBackgroundTaskInvalid;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
