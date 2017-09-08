//
// Created by apple on 2017/9/7.
// Copyright (c) 2017 CyberAgent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BaseViewController : UIViewController

#pragma mark 状态栏文本样式
@property(nonatomic) UIStatusBarStyle statusBarStyle;

#pragma mark 状态栏是否可见
@property(nonatomic) BOOL statusBarVisibility;

@end