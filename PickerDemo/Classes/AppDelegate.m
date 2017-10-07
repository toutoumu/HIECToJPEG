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
#import "PPViewController.h"
#import "CameraViewController.h"
#import "VideoViewController.h"

@implementation AppDelegate

static CGFloat _preBrightness;//保存之前的屏幕亮度

#pragma mark 获取应用打开之前的屏幕亮度

+ (CGFloat)getScreenBrightness {
    return _preBrightness;
}

#pragma mark 程序加载完毕

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Configure NBULog
#if defined (DEBUG) || defined (TESTING)
    // Add dashboard logger
    //[NBULog addDashboardLogger];
#endif
    // pods 项目 >> build settings >>apple llvm 设置 debug 中 debug1 = 1 改为 debug = 1 这样就有日志了
    NBULogTrace();

    UIColor *tintColor = [UIColor colorWithRed:(CGFloat) (0 / 255.0) green:(CGFloat) (0 / 255.0) blue:(CGFloat) (0 / 255.0) alpha:1.0];
    self.window.tintColor = tintColor;
    [UISwitch appearance].tintColor = tintColor;
    [UISwitch appearance].onTintColor = tintColor;

    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];//返回按钮默认颜色
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];//标题栏背景色

    // 在沙盒中创建相册
    [NBUAssetUtils createAlbum:@"Video"];
    [NBUAssetUtils createAlbum:@"Deleted"];
    [NBUAssetUtils createAlbum:@"Beauty"];
    [NBUAssetUtils createAlbum:@"Decrypted"];

    //[self initRoot];
    // 因为Storyboard.storyboard中的rootViewController就是UINavigationController类型
    self.navController = (UINavigationController *) self.window.rootViewController;

    return YES;
}

#pragma mark  程序失去焦点, 控制中心上拉, 通知中心下拉, 按下home键

- (void)applicationWillResignActive:(UIApplication *)application {
    // 应用程序被通知栏,底部上拉通知中心覆盖,或者进入后台,恢复屏幕亮度
    [[UIScreen mainScreen] setBrightness:_preBrightness];
    // 不阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

#pragma mark 退到后台, 按下home键

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // 应用程序退到后台, 如果当前还是启动应用程序时候的密码输入界面,或者是已经输入密码进入了相机页面,那么堆栈不需要清空.
    UIViewController *controller = self.navController.viewControllers[self.navController.viewControllers.count - 1];
    if (controller != nil) {
        if ([controller isKindOfClass:[CameraViewController class]] || [controller isKindOfClass:[PPViewController class]] || [controller isKindOfClass:[VideoViewController class]]) {
            return;
        }
        // 如果不是密码页面,或者是拍摄页面,清空堆栈
        [self.navController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark 程序从后台回到前台进入前台 打开应用, 从其他应用切换到该应用

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

#pragma mark 程序获取焦点进入前台 从其他应用切换到该应用, 控制中心收回, 通知中心收回等

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 每次进入该应用的时候记录,进入之前屏幕亮度
    _preBrightness = [UIScreen mainScreen].brightness;

    // 阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    // 设置屏幕亮度,如果是管理员用户,且当前是拍摄页面,进入时设置屏幕亮度为0
    UIViewController *controller = self.navController.viewControllers[self.navController.viewControllers.count - 1];
    if (controller != nil && [controller isKindOfClass:[CameraViewController class]]) {
        CameraViewController *cameraViewController = (CameraViewController *) controller;
        // 如果没有弹出密码输入页面
        if ([cameraViewController presentedViewController] == nil) {
            [[UIScreen mainScreen] setBrightness:0];
        }
    }
}

#pragma mark 初始化页面

- (void)initRoot {
    //返回的是包含状态栏的Rect
    CGRect bound = [[UIScreen mainScreen] bounds];
    //返回的是不包含状态栏的Rect
    //CGRect appBound =  [[UIScreen mainScreen] applicationFrame];

    // 三种方式初始化ViewController
    // 1. 初始化root视图,这里调用的是init方法来初始化,init方法会默认调用
    // - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil; 加载名称为RootViewController的nib文件
    //RootViewController *rootView = [[RootViewController alloc]initWithNibName:@"RootViewController" bundle:nil ];

    // 2. 相册界面
    //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    //UIViewController *rootView =  [mainStoryboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    //[NBUAssetUtils setPassword:@"111111"];// 全局密码缓存密码

    // 相机页面
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    //VideoViewController *rootView =  [storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"];

    // 3. 初始化界面,密码输入页面
    PPViewController *rootView = [[PPViewController alloc] init];

    //初始化导航控制器，并指定该导航控制器的根视图控制器为上面建立的rootView
    //self.navController = [[RTRootNavigationController alloc]initWithRootViewController:rootView];
    self.navController = [[UINavigationController alloc] initWithRootViewController:rootView];
    self.navController.navigationBarHidden = YES; // 隐藏导航栏

    // 初始化Window
    self.window = [[UIWindow alloc] initWithFrame:bound];
    self.window.backgroundColor = [UIColor whiteColor]; //设置背景色为白色
    //设置窗体(window)根视图控制器——这个视图控制器负责配置当窗体显示时最先显示的视图。要让你的视图控制器的内容显示在窗体中，需要去设置窗体的根视图控制器为你的视图控制器。
    [self.window setRootViewController:self.navController];
    [self.window makeKeyAndVisible];//这行代码会让包含了视图控制器视图的Window窗口显示在屏幕上。
}
@end

