//
//  PPViewController.m
//  PinPadExample
//
//  Created by Aleks Kosylo on 1/31/14.
//  Copyright (c) 2014 Aleks Kosylo. All rights reserved.
//

#import "PPViewController.h"
#import "PPPinPadViewController.h"
#import "CameraViewController.h"
@interface PPViewController ()
{
    int inputCount;
}
@end
static NSString *_password;//密码存储对应的字段名称

@implementation PPViewController

+(void)initialize{
    _password = @"_password";
}

+(NSString *)password{
    return _password;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    inputCount = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    PPPinPadViewController * pinViewController = [[PPPinPadViewController alloc] init];
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [accountDefaults objectForKey:_password];// 读取设置的密码
    if (!password || [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        pinViewController.isSettingPinCode = YES;//如果没有设置密码那么,设置模式为 设置密码模式
    }
    pinViewController.delegate = self;
    pinViewController.pinTitle = @"请输入密码";
    pinViewController.errorTitle = @"密码错误";
    pinViewController.cancelButtonHidden = NO; //default is False
    pinViewController.backgroundImage = [UIImage imageNamed:@"pinViewImage"];
    //if you need remove the background set a empty UIImage ([UIImage new]) or set a background color
    //pinViewController.backgroundColor = [UIColor blueColor]; //default is a darkGrayColor
    // 将pinViewController作为当前ViewController的视图
    [self presentViewController:pinViewController animated:YES completion:NULL];
}

- (BOOL)checkPin:(NSString *)pin {//密码验证
    inputCount ++;
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [accountDefaults objectForKey:_password];
    BOOL b = [pin isEqualToString: password];
    if (!b && inputCount >= 3) {//如果输错了三次,进入访客模式
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
        CameraViewController *cameraView =  [mainStoryboard instantiateViewControllerWithIdentifier:@"cameraControllerguest"];
        cameraView.albumName = @"Album";//默认相册为Album
        cameraView.isGuest = YES;//设置为访客模式
        [self.navigationController pushViewController:cameraView animated:YES];
        [self dismissViewControllerAnimated:true completion:nil];
        return NO;
        /*//退出应用
         NSArray *arr = [[NSArray alloc]init];
        [arr objectAtIndex:2];
        return NO;*/
    }
    return b;
}

- (NSInteger)pinLenght {//密码长度
    return 6;
}

- (void)pinPadSuccessPin{//密码输入正确后 optional, when the user set a correct pin
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    CameraViewController *cameraView =  [mainStoryboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
    cameraView.albumName = @"Album";
    cameraView.isGuest = NO;
    [self.navigationController pushViewController:cameraView animated:YES];
}

- (void)pinPadWillHide{//optional, before the pin pad hide
}

- (void)pinPadDidHide{//optional, after pin pad hide
}

- (void)userPassCode:(NSString *)newPassCode{ //设置新密码 optional, set new user passcode
    NSLog(@"%@",newPassCode);
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:newPassCode forKey:_password];
    [accountDefaults synchronize];
    
}










@end
