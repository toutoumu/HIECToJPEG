//
// Created by apple on 2017/9/7.
// Copyright (c) 2017 CyberAgent Inc. All rights reserved.
//

#import "BaseViewController.h"


@implementation BaseViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _statusBarVisibility = YES;
        _statusBarStyle = UIStatusBarStyleLightContent;
    }
    return self;
}

// 将要设置的状态栏文字样式
- (UIStatusBarStyle)preferredStatusBarStyle {
    return _statusBarStyle;
}


- (BOOL)prefersStatusBarHidden {
    return _statusBarVisibility;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle {
    _statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setStatusBarVisibility:(BOOL)statusBarVisibility {
    _statusBarVisibility = statusBarVisibility;
    [self setNeedsStatusBarAppearanceUpdate];
}

@end