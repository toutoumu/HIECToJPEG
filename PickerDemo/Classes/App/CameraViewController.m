//
//  ViewController.m
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "PPViewController.h"
#import "AlbumViewController.h"
#import "CameraViewController.h"

// 照片拍摄界面
@implementation CameraViewController {
    NSMutableDictionary *_vibeDictionary;//震动相关
    int _inputCount;// 密码输入次数
    int _clickCount;// 点击打开相册的次数
    BOOL _prefersStatusBarHidden;//是否隐藏状态栏
    UITapGestureRecognizer *_tapGesture;// 触摸手势
}

#pragma mark 从storyboard初始化默认会调用这个方法

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _inputCount = 0; //重置密码输入次数
        _clickCount = 0; //重置点击次数
        _tapGesture = nil;// 触摸手势
        _prefersStatusBarHidden = NO;//进入页面时不隐藏状态栏

        // 初始化震动配置
        _vibeDictionary = [NSMutableDictionary dictionary];
        NSMutableArray *array = [NSMutableArray array];
        if (@available(iOS 11.0, *)) {
            [array addObject:@YES];
            [array addObject:@10];//震动时长
            _vibeDictionary[@"VibePattern"] = array;
            _vibeDictionary[@"Intensity"] = @0.5F;// 震动强度
        } else {
            [array addObject:@YES];
            [array addObject:@30];//震动时长
            _vibeDictionary[@"VibePattern"] = array;
            _vibeDictionary[@"Intensity"] = @1.0F;// 震动强度
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 必须在Storyboard中设置fd_prefersNavigationBarHidden属性为true才能使用状态栏,标题栏跟随UIViewController滚动
    //self.navigationController.fd_prefersNavigationBarHidden = YES;
    // 禁止控制器侧滑返回,这个属性也可以在UIViewController中设置
    //self.fd_interactivePopDisabled = YES;

    // 只有当未设置相册时候才使用默认
    if (self.albumName == nil) {
        self.albumName = @"Album";
    }

    self.cameraView.fixedFocusPoint = YES;// 是否固定对焦位置
    self.cameraView.shootAfterFocus = NO;// 是否对焦后拍摄
    self.cameraView.showPreviewLayer = NO;// 是否显示预览图层
    self.cameraView.animateLastPictureImageView = NO;//最后一张图片不需要动画
    self.cameraView.captureSuccess = ^{// 震动
        AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, _vibeDictionary);
    };
    // 拍摄完成后的回调,注意这里是非ui线程
    self.cameraView.captureResultBlock = ^(NSData *data, UIImage *image, NSError *error) {
        if (!error) {
            _clickCount = 0;
            [NBUAssetUtils saveImage:image imageData:data toAlubm:_albumName withFileName:[NBUAssetUtils createFileName]];
        }
    };
    //为拍摄按钮添加触摸手势 , 第一次点击设置好相机参数,然后移除掉手势, 让其调用 takePicture
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handTap:)];
    [_shootButton addGestureRecognizer:_tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 隐藏状态栏和标题栏
    [self changeStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // 设置屏幕亮度为0
    [[UIScreen mainScreen] setBrightness:0];
    // 启用拍摄按钮 Enable shootButton
    _shootButton.userInteractionEnabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self changeStatusBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // 禁用拍摄按钮 Disable shootButton
    _shootButton.userInteractionEnabled = NO;
}

#pragma mark 内存不足

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.cameraView.sequenceCaptureInterval = 5;
}

#pragma mark - 状态栏相关
#pragma mark 必须重载这个才能隐藏状态栏

- (BOOL)prefersStatusBarHidden {
    return _prefersStatusBarHidden;
}

#pragma mark 是否隐藏状态栏

- (void)changeStatusBarHidden:(BOOL)hidden {
    _prefersStatusBarHidden = hidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark 状态栏文字样式

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - 其他方法

#pragma mark 重写set方法创建相册

- (void)setAlbumName:(NSString *)albumName {
    _albumName = albumName;
    [NBUAssetUtils createAlbum:_albumName];
}

#pragma mark tap操作

- (void)handTap:(UITapGestureRecognizer *)gesture {
    if (self.cameraView.shootAfterFocus) {// 如果是触摸后拍摄直接调用tapped方法
        [self.cameraView tapped:gesture];
    } else {
        [self.cameraView takePicture:_shootButton];
    }
}

#pragma mark 双击打开相册, 打开相册之前需要输入密码

- (IBAction)doubleClick:(id)sender {
    if (_clickCount < 4) {
        _clickCount++;
        return;
    }
    _clickCount = 0;
    // 显示密码输入框
    PPPinPadViewController *pinController = [self.storyboard instantiateViewControllerWithIdentifier:@"PPPinPadViewController"];
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:[PPViewController pwdKey]];
    if (pwd == nil || [pwd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        pinController.isSettingPinCode = YES;//如果没有设置密码,设置为设置密码模式
    }
    pinController.delegate = self;
    pinController.pinTitle = @"请输入密码";
    pinController.errorTitle = @"密码正确再来一次";
    pinController.cancelButtonHidden = NO; //default is False
    //弹出密码输入界面
    [self presentViewController:pinController animated:YES completion:NULL];
}

#pragma mark - 密码输入框对应的协议方法实现
#pragma mark 检查密码

- (BOOL)checkPin:(NSString *)pin {//密码验证
    _inputCount++;
    NSString *pwd = [[NSUserDefaults standardUserDefaults] objectForKey:[PPViewController pwdKey]];
    BOOL b = [pin isEqualToString:pwd];
    if (!b && _inputCount >= 3) {
        // 三次输错强制退出 , 这里这么做是因为让他抛错退出
        [NBUAssetUtils exitApplication];
    }
    return b;
}

#pragma mark 密码长度

- (NSInteger)pinLength {//密码长度
    return 6;
}

#pragma mark 密码输入成功

- (void)pinPadSuccessPin {//密码输入正确后 optional, when the user set a correct pin
    _clickCount = 0;
    _inputCount = 0;

    AlbumViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    controller.onlyLoadDocument = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)userPassCode:(NSString *)newPassCode { //设置新密码
    NBULogInfo(@"新的密码:%@", newPassCode);
    NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
    [accountDefaults setObject:newPassCode forKey:[PPViewController pwdKey]];
    [accountDefaults synchronize];
}

@end
