//
//  AppDelegate.m
//  PickerDemo
//
//  Created by Ernesto Rivera on 2013/11/25.
//  Copyright (c) 2012-2014 CyberAgent Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AppDelegate.h"
#import "VideoViewController.h"

@implementation AppDelegate

#pragma mark 程序加载完毕

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Configure NBULog
#if defined (DEBUG) || defined (TESTING)
    // Add dashboard logger
    //[NBULog addDashboardLogger];
#endif
    // pods 项目 >> build settings >> 搜索 Preprocessor Macros 设置 debug 中 debug1 = 1 改为 debug = 1 这样就有日志了
    // NBULogTrace();

    // 初始化配置信息
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (![userDefaults objectForKey:@"voice_to_shoot"]) {
        [self registerDefaultsFromSettingsBundle];
    }

    // 在沙盒中创建相册
    [NBUAssetUtils createAlbum:NBUAssetUtils.CropDirectory];
    [NBUAssetUtils createAlbum:NBUAssetUtils.DeletedDirectory];
    [NBUAssetUtils createAlbum:NBUAssetUtils.HEICDirectory];
    [NBUAssetUtils createAlbum:NBUAssetUtils.JPEGDirectory];

    UIColor *tintColor = [UIColor colorWithRed:(CGFloat) (0 / 255.0) green:(CGFloat) (0 / 255.0) blue:(CGFloat) (0 / 255.0) alpha:1.0];
    self.window.tintColor = tintColor;
    [UISwitch appearance].tintColor = tintColor;
    [UISwitch appearance].onTintColor = tintColor;

    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];//返回按钮默认颜色
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];//标题栏背景色

    //[self initRoot];
    // 因为Storyboard.storyboard中的rootViewController就是UINavigationController类型
    self.navController = (UINavigationController *) self.window.rootViewController;

    return YES;
}

#pragma mark  程序失去焦点, 控制中心上拉, 通知中心下拉, 按下home键

- (void)applicationWillResignActive:(UIApplication *)application {
    // 不阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark 退到后台, 按下home键

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

#pragma mark 程序从后台回到前台进入前台 打开应用, 从其他应用切换到该应用

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

#pragma mark 程序获取焦点进入前台 从其他应用切换到该应用, 控制中心收回, 通知中心收回等

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

/**
 * 注册所有(Settings.bundle)默认配置,需要检查是否已经注册过
 */
- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if (!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }

    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];

    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key && [[prefSpecification allKeys] containsObject:@"DefaultValue"]) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

@end

