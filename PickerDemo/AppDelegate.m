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
#import "NBULog.h"
@implementation AppDelegate
static CGFloat preBrightness;//保存之前的屏幕亮度

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // 读取屏幕亮度
    preBrightness = [UIScreen mainScreen].brightness;
    
    // Configure NBULog
#if defined (DEBUG) ||  defined (TESTING)
    // Add dashboard logger
    //[NBULog addDashboardLogger];
#endif
    
    NBULogTrace();
    // pods 项目 >> build settings >>apple llvm 设置 debug 中 debug1 = 1 改为 debug = 1 这样就有日志了
    
    // 系统版本大于7.0才会执行这里,Customize iOS 7 appearance
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        UIColor * tintColor = [UIColor colorWithRed:76.0/255.0 green:19.0/255.0 blue:136.0/255.0 alpha:1.0];
        //UIColor * tintColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0];
        self.window.tintColor = tintColor;
        //[UIButton appearance].tintColor = tintColor;
        //[[UIButton appearance] setTitleColor:tintColor forState:UIControlStateNormal];
        [UISwitch appearance].tintColor = tintColor;
        [UISwitch appearance].onTintColor = tintColor;
        
        [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];//标题栏背景色
        [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];//返回按钮默认颜色
        [self initRoot];
    }
    
    return YES;
}


-(void) initRoot{
    //返回的是带有状态栏的Rect
    CGRect bound = [[UIScreen mainScreen]bounds];
    NSLog(@"boundwith:%f    boundheight:%f",bound.size.width,bound.size.height);
    NSLog(@"boundx:%f    boundy:%f",bound.origin.x,bound.origin.y);
    NSLog(@"%@",NSStringFromCGRect(bound));
    
    //2012-08-03 23:21:45.716 DinkMixer[599:c07] boundwith:320.000000    boundheight:480.000000
    //2012-08-03 23:21:45.719 DinkMixer[599:c07] boundx:0.000000    boundy:0.000000
    
    CGRect appBound =  [[UIScreen mainScreen] applicationFrame];  //返回的是不带有状态栏的Rect
    NSLog(@"appBoundwith:%f    boundheight:%f",appBound.size.width,appBound.size.height);
    NSLog(@"appBoundx:%f    boundy:%f",appBound.origin.x,appBound.origin.y);
    NSLog(@"%@",NSStringFromCGRect(appBound));
    //2012-08-03 23:21:45.720 DinkMixer[599:c07] appBoundwith:320.000000    boundheight:460.000000
    //2012-08-03 23:21:45.720 DinkMixer[599:c07] appBoundx:0.000000    boundy:20.000000
    //很明显状态栏占用了空间20像素
    
    // 初始化root视图,这里调用的是init方法来初始化,init方法会默认调用
    // - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil; 加载名称为RootViewController的nib文件
    //RootViewController *rootView = [[RootViewController alloc]initWithNibName:@"RootViewController" bundle:nil ];
    
    // 相册界面
    //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    //UIViewController *rootView =  [mainStoryboard instantiateViewControllerWithIdentifier:@"UIViewController"];
    
    // 密码输入页面
    PPViewController *rootView = [[PPViewController alloc] init];
    ////创建一个导航控制器，并指定该导航控制器的根视图控制器为上面建立的rootView
    // 下面这两句和下面这句一样
    self.navController = [[UINavigationController alloc]initWithRootViewController:rootView];
    _navController.navigationBarHidden = YES; // 隐藏导航栏
    
    //返回的是带有状态栏的矩形
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor]; //设置背景色为白色
    
    //创建一个导航控制器，并指定该导航控制器的根
    //窗体(window)有一个根视图控制器——这个视图控制器负责配置当窗体显示时最先显示的视图。要让你的视图控制器的内容显示在窗体中，需要去设置窗体的根视图控制器为你的视图控制器。
    [self.window setRootViewController: self.navController];
    [self.window makeKeyAndVisible];//这行代码会让包含了视图控制器视图的Window窗口显示在屏幕上。
}


// 按下home键 1
-(void)applicationWillResignActive:(UIApplication *)application{
    // 恢复屏幕亮度
    [[UIScreen mainScreen] setBrightness:preBrightness];
    // 不阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
}

// 按下home键,退到后台 2
-(void)applicationDidEnterBackground:(UIApplication *)application{
    // 恢复屏幕亮度
    // [[UIScreen mainScreen] setBrightness:preBrightness];
    // 不阻止锁屏
    // [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
}

// 进入前台 1
-(void)applicationWillEnterForeground:(UIApplication *)application{
    // 阻止锁屏
    // [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}

// 进入前台 2
-(void)applicationDidBecomeActive:(UIApplication *)application{
    // 阻止锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}


@end

