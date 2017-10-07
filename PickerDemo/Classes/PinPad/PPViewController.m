//
//  PPViewController.m
//  PinPadExample
//
//  Created by Aleks Kosylo on 1/31/14.
//  Copyright (c) 2014 Aleks Kosylo. All rights reserved.
//

#import "AppDelegate.h"
#import "PPViewController.h"
#import "CameraViewController.h"
#import "VideoViewController.h"

static NSString *_pwdKey;//密码存储对应的字段名称

@implementation PPViewController {
    int _inputCount;
}

+ (void)initialize {
    _pwdKey = @"_password";
}

+ (NSString *)pwdKey {
    return _pwdKey;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _inputCount = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    PPPinPadViewController *pinController = [self.storyboard instantiateViewControllerWithIdentifier:@"PPPinPadViewController"];
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:_pwdKey];// 读取设置的密码
    if (!pwd || [pwd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        pinController.isSettingPinCode = YES;//如果没有设置密码那么,设置模式为 设置密码模式
    }

    pinController.delegate = self;
    pinController.pinTitle = @"请输入密码";
    pinController.errorTitle = @"密码正确再来一次";
    pinController.cancelButtonHidden = NO; //是否隐藏取消按钮
    // 将pinController作为当前ViewController的视图
    [self presentViewController:pinController animated:YES completion:NULL];
}

- (BOOL)checkPin:(NSString *)pin {//密码验证
    _inputCount++;
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:_pwdKey];
    if ([pin isEqualToString:pwd]) {
        [NBUAssetUtils setPassword:pwd];// 全局密码缓存密码
        return YES;
    }
    if (_inputCount >= 3) {//如果输错了三次,进入访客模式
        _inputCount = 0;
        [NBUAssetUtils setPassword:@"198868"];
        VideoViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"];
        [self.navigationController pushViewController:controller animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        //退出应用
        //[NBUAssetUtils exitApplication];
    }
    return NO;
}

- (NSInteger)pinLength {//密码长度
    return 6;
}

- (void)pinPadSuccessPin {//密码输入正确后
    AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
    appDelegate.isAdmin = YES;
    CameraViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
    controller.albumName = @"Album";//设置默认相册
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)userPassCode:(NSString *)newPassCode { //设置新密码
    NBULogInfo(@"%@", newPassCode);
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:newPassCode forKey:_pwdKey];
    [accountDefaults synchronize];
}

@end
