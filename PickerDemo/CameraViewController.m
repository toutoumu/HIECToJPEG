//
//  ViewController.m
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "TTFIleUtils.h"
#import "AlbumViewController.h"
#import "NBUAsset.h"
#import "PPViewController.h"
#import "SelectAlbumViewController.h"
// 照片拍摄界面
@implementation CameraViewController
{
    int inputCount;// 密码输入次数
    int clickCount;// 点击屏幕的次数
    CGFloat preBrightness;// 之前的屏幕亮度
    UITapGestureRecognizer *tapGesture;// 触摸手势
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化参数
    inputCount = 0; //重置密码输入次数
    clickCount = 0; //重置点击次数
    preBrightness = [UIScreen mainScreen].brightness;// 读取屏幕亮度
    //为拍摄按钮注册事件 , 第一次点击设置好相机参数
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handTap:)];
    [_shootButton addGestureRecognizer:tapGesture];
    
    // 只有当未设置相册时候才使用默认
    if(self.albumName == nil){
        self.albumName = @"Album";
    }
    
    // 访客保存到相册
    if (_isGuest == YES) {
        self.cameraView.recycleFocus = YES;
        self.cameraView.savePicturesToLibrary = YES;
    }
    //self.cameraView.savePicturesToLibrary = YES;
    //self.cameraView.targetLibraryAlbumName = @"abb";
    // 拍摄完成后的回调,注意这里是非ui线程
    self.cameraView.captureResultBlock = ^(UIImage * image, NSError * error){
        if (!error){
            clickCount = 0;
            [TTFIleUtils saveImage:image toAlubm:_albumName];
        }
    };
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // 设置屏幕亮度为0
    if(_isGuest == NO){
        [[UIScreen mainScreen] setBrightness:0];
    }
    
    // 隐藏状态栏和标题栏
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController prefersStatusBarHidden];
    
    // Enable shootButton
    _shootButton.userInteractionEnabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    // 恢复屏幕亮度
    if (_isGuest == NO){
        [[UIScreen mainScreen] setBrightness:preBrightness];
    }
    // Disable shootButton
    _shootButton.userInteractionEnabled = NO;
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Disconnect shoot button
    //[_shootButton removeTarget:nil action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.cameraView.sequenceCaptureInterval = 5;
}

#pragma mark 必须重载这个才能隐藏状态栏
- (BOOL)prefersStatusBarHidden{
    return YES;
}

#pragma mark - 其他方法
#pragma mark 重写set方法创建相册
-(void)setAlbumName:(NSString *)albumName{
    _albumName = albumName;
    [TTFIleUtils createAlbum:_albumName];
}

#pragma mark 第一次点击设置好相机参数 ,并移除事件监听
- (void) handTap:(UITapGestureRecognizer*) gesture
{
    self.cameraView.recycleFocus= YES;
    [self.cameraView tapped:gesture];
    [_shootButton removeGestureRecognizer:tapGesture];
    tapGesture = nil;
}

#pragma mark 双击打开相册,打开相册之前需要输入密码
- (IBAction)doubleClick:(id)sender {
    // 访客不允许访问
    if(_isGuest){
        return;
    }
    
    if (clickCount < 4) {
        clickCount ++;
        return;
    }
    clickCount = 0;
    // 显示密码输入框
    PPPinPadViewController * pinViewController = [[PPPinPadViewController alloc] init];
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [accountDefaults objectForKey:[PPViewController password]];
    if (password == nil|| [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        pinViewController.isSettingPinCode = YES;//如果没有设置密码,设置为设置密码模式
    }
    pinViewController.delegate = self;
    pinViewController.pinTitle = @"请输入密码";
    pinViewController.errorTitle = @"密码错误";
    pinViewController.cancelButtonHidden = NO; //default is False
    pinViewController.backgroundImage = [UIImage imageNamed:@"pinViewImage"];
    //if you need remove the background set a empty UIImage ([UIImage new]) or set a background color
    //pinViewController.backgroundColor = [UIColor blueColor]; //default is a darkGrayColor
    //显示密码输入框
    [self presentViewController:pinViewController animated:YES completion:NULL];
    
}

#pragma mark - 密码输入框对应的协议方法实现
#pragma mark 检查密码
- (BOOL)checkPin:(NSString *)pin {//密码验证
    inputCount ++;
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    NSString *password = [accountDefaults objectForKey:[PPViewController password]];
    BOOL b = [pin isEqualToString: password];
    if (!b && inputCount >= 3) {
        // 三次输错强制退出 , 这里这么做是因为让他抛错退出
        NSArray *arr = [[NSArray alloc]init];
        [arr objectAtIndex:2];
        return NO;
    }
    return b;
}

#pragma mark 密码长度
- (NSInteger)pinLenght {//密码长度
    return 6;
}

#pragma mark 密码输入成功
- (void)pinPadSuccessPin{//密码输入正确后 optional, when the user set a correct pin
    clickCount = 0;
    inputCount = 0;
    AlbumViewController *controll = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    [self.navigationController pushViewController:controll animated:YES];
}
#pragma mark 密码输入框将要隐藏
- (void)pinPadWillHide{//optional, before the pin pad hide
}

#pragma mark 密码输入框隐藏
- (void)pinPadDidHide{//optional, after pin pad hide
}

#pragma mark 密码设置成功
- (void)userPassCode:(NSString *)newPassCode{ //设置新密码 optional, set new user passcode
    NSLog(@"%@",newPassCode);
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:newPassCode forKey:[PPViewController password]];
    [accountDefaults synchronize];
}

@end
