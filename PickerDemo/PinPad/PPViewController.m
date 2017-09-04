//
//  PPViewController.m
//  PinPadExample
//
//  Created by Aleks Kosylo on 1/31/14.
//  Copyright (c) 2014 Aleks Kosylo. All rights reserved.
//

#import "AppDelegate.h"
#import "PPViewController.h"
#import "PPPinPadViewController.h"
#import "CameraViewController.h"
#import "TTFIleUtils.h"
#import "VideoViewController.h"

static NSString *_pwdKey;//密码存储对应的字段名称

@implementation PPViewController{
    int _inputCount;
}

+(void)initialize{
    _pwdKey = @"_password";
}

+(NSString *)pwdKey{
    return _pwdKey;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    _inputCount = 0;
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    
    PPPinPadViewController * pinViewController =  [self.storyboard instantiateViewControllerWithIdentifier:@"PPPinPadViewController"];
    //[[PPPinPadViewController alloc] init];
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:_pwdKey];// 读取设置的密码
    if (!pwd || [pwd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        pinViewController.isSettingPinCode = YES;//如果没有设置密码那么,设置模式为 设置密码模式
    }
    
    pinViewController.delegate = self;
    pinViewController.pinTitle = @"请输入密码";
    pinViewController.errorTitle = @"密码正确再来一次";
    pinViewController.cancelButtonHidden = NO; //default is False
    //pinViewController.backgroundImage = [UIImage imageNamed:@"pinViewImage"];
    //if you need remove the background set a empty UIImage ([UIImage new]) or set a background color
    //pinViewController.backgroundColor = [UIColor blueColor]; //default is a darkGrayColor
    // 将pinViewController作为当前ViewController的视图
    [self presentViewController:pinViewController animated:YES completion:NULL];
}

- (BOOL)checkPin:(NSString *)pin {//密码验证
    _inputCount ++;
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:_pwdKey];
    if ([pin isEqualToString:pwd]) {
        [TTFIleUtils setPassword:pin];// 全局密码缓存密码
        return YES;
    }
    if (_inputCount >= 1) {//如果输错了三次,进入访客模式
        _inputCount = 0;
        [TTFIleUtils setPassword:@"198868"];
        //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
        VideoViewController *cameraController =  [self.storyboard instantiateViewControllerWithIdentifier:@"VideoViewController"];
        [self.navigationController pushViewController:cameraController animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        //退出应用
        //[TTFIleUtils exitApplication];
    }
    return NO;
}

- (NSInteger)pinLenght {//密码长度
    return 6;
}

- (void)pinPadSuccessPin{//密码输入正确后 optional, when the user set a correct pin
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    appDelegate.isAdmin = YES;
    //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    CameraViewController *cameraView =  [self.storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
    cameraView.albumName = @"Album";//设置默认相册
    [self.navigationController pushViewController:cameraView animated:YES];
}

- (void)pinPadWillHide{//optional, before the pin pad hide
}

- (void)pinPadDidHide{//optional, after pin pad hide
}

- (void)userPassCode:(NSString *)newPassCode{ //设置新密码 optional, set new user passcode
    NBULogInfo(@"%@",newPassCode);
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:newPassCode forKey:_pwdKey];
    [accountDefaults synchronize];
}










@end
