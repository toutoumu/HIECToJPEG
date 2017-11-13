//
//  CropViewController.m
//  PickerDemo
//
//  Created by Ernesto Rivera on 2012/07/31.
//  Copyright (c) 2012-2017 CyberAgent Inc.
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

#import "CropViewController.h"

@implementation CropViewController {

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        //包含状态栏的Rect
        self.maximumScaleFactor = 10.0;
        self.cropGuideSize = [[UIScreen mainScreen] bounds].size;

        __unsafe_unretained CropViewController *weakSelf = self;
        self.resultBlock = ^(UIImage *image) {// 剪切后的回调方法
            weakSelf.cropView.image = image;
        };

        self.startBlock = ^() {// 调用剪切时调用
            [weakSelf showProgressHUDWithMessage:@"剪切中..."];
        };

        self.finishBlock = ^() {//剪切完成之后调用
            [weakSelf.navigationController popViewController:weakSelf];
            [weakSelf hideProgressHUD:YES];
        };
    }
    return self;
}

- (void)viewDidLoad {
    // 使内容在状态栏下显示(状态栏覆盖在其上方)
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scroolView.scrollsToTop = NO;//点击状态栏不让其滚动到顶部
    if (@available(iOS 11.0, *)) {
        self.scroolView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }

    // 透明状态栏
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [super viewDidLoad];
}

/**
 * 状态栏样式
 * @return
 */
- (UIStatusBarStyle)preferredStatusBarStyle {//
    return UIStatusBarStyleLightContent;//UIStatusBarStyleDefault;
}

- (void)setCropView:(NBUCropView *)cropView {
    super.cropView = cropView;
    // The image can be downsized until it fits inside the cropGuideView
    cropView.allowAspectFit = YES;
}


- (void)apply:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"提示"
                                message:@"该操作无法还原,确定要应用剪切?"
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:nil]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"剪切" action:^{
                           [super apply:sender];//调用父类的剪切操作
                       }], nil] show];
}


#pragma mark - Action Progress
#pragma mark 进度条

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

#pragma mark 显示进度条

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.label.text = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD showAnimated:YES];
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

#pragma mark 隐藏进度条

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hideAnimated:animated];
    self.fd_interactivePopDisabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark 显示1.6秒信息提示

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD showAnimated:YES];
        self.progressHUD.label.text = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hideAnimated:YES afterDelay:0.6];
    } else {
        [self.progressHUD hideAnimated:YES];
    }
    //这里修改了,为了解决删除文件时候,右滑返回,会在弹窗时候可用
    //self.fd_interactivePopDisabled = NO;
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    //弹出的时候禁用,1.6秒之后启用
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    double delayInSeconds = 1.6;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        self.fd_interactivePopDisabled = NO;
        self.navigationController.navigationBar.userInteractionEnabled = YES;
    });
}

#pragma mark 设置进度条消息

- (void)setProgressMessage:(NSString *)message {
    if (message) {
        if (_progressHUD != nil && !_progressHUD.isHidden) {
            self.progressHUD.label.text = message;
        }
    }
}

@end

