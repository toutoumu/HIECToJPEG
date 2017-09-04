//
//  UIViewController_BackButtonHandler.h
//  PickerDemo
//
//  Created by LiuBin on 4/8/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//返回按钮监听
@protocol BackButtonHandlerProtocol <NSObject>
@optional
// Override this method in UIViewController derived class to handle 'Back' button click
-(BOOL)navigationShouldPopOnBackButton;
@end

@interface UIViewController (BackButtonHandler) <BackButtonHandlerProtocol>
@end

