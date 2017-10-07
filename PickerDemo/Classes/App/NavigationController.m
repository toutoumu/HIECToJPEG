//
// Created by apple on 2017/9/7.
// Copyright (c) 2017 CyberAgent Inc. All rights reserved.
//

#import "NavigationController.h"

/**
 * http://www.jianshu.com/p/0d4337b2e18a
 * [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
 * 设置状态栏样式已经过时了,我们可以继承 UINavigationController 后通过重载 preferredStatusBarStyle 方法来修改状态栏文字样式,
 * 仅重载此方法不能够在 UIViewController 中修改状态栏文字样式, 因此我们重载 childViewControllerForStatusBarStyle 方法,
 * 将状态栏颜色的修改交给当前显示的 UIViewController.
 * 当我们需要在 UIViewController 显示出来以后再次修改 状态栏颜色 只需要 调用 setNeedsStatusBarAppearanceUpdate 方法通知系统
 * 调用 preferredStatusBarStyle 方法来设置新的状态栏文字颜色
 *
 */
@implementation NavigationController

- (void)viewDidLoad {
    // 在这里设置标题栏的默认样式
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.barTintColor = nil;
    self.navigationBar.shadowImage = nil;
    self.navigationBar.translucent = YES;//透明
    self.navigationBar.barStyle = UIBarStyleBlack;//黑色
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;//默认的状态栏文字颜色(黑色)
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;//将状态栏文字样式的修改交给当前显示的 UIViewController
}

@end