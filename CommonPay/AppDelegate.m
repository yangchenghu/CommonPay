//
//  AppDelegate.m
//  CommonPay
//
//  Created by yangchenghu on 16/1/4.
//  Copyright © 2016年 yangchenghu. All rights reserved.
//

#import "AppDelegate.h"

#import "CommonPayManager.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url NS_DEPRECATED_IOS(2_0, 9_0, "Please use application:openURL:options:") __TVOS_PROHIBITED
{
    NSInteger iResult = [[CommonPayManager sharedInstance] handleUrlInAppDelegate:url];
    
    if (iResult == 1) {
        return YES;
    }
    else if (iResult == 0){
        return NO;
    }
    else {
    //其他程序处理
        return NO;
    }
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation NS_DEPRECATED_IOS(4_2, 9_0, "Please use application:openURL:options:") __TVOS_PROHIBITED
{
    NSInteger iResult = [[CommonPayManager sharedInstance] handleUrlInAppDelegate:url];
    
    if (iResult == 1) {
        return YES;
    }
    else if (iResult == 0){
        return NO;
    }
    else {
        //其他程序处理
        return NO;
    }
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options NS_AVAILABLE_IOS(9_0)
{
    NSInteger iResult = [[CommonPayManager sharedInstance] handleUrlInAppDelegate:url];
    
    if (iResult == 1) {
        return YES;
    }
    else if (iResult == 0){
        return NO;
    }
    else {
        //其他程序处理
        return NO;
    }
}




@end
