//
//  VideoViewController.m
//  PickerDemo
//
//  Created by apple on 2017/7/27.
//  Copyright © 2017年 CyberAgent Inc. All rights reserved.
//

#import "VideoViewController.h"
#import "AlbumViewController.h"

@implementation VideoViewController {
    CGRect _cameraFrame;
    BOOL _prefersStatusBarHidden;//是否隐藏状态栏
    UISwipeGestureRecognizer *_leftGestureRecognizer;
    UISwipeGestureRecognizer *_rightGestureRecognizer;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _prefersStatusBarHidden = NO;//进入页面时不隐藏状态栏
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //获取SettingsBundle信息
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.takesPicturesWithVolumeButtons = [userDefaults boolForKey:@"voice_to_shoot"];// 音量键拍摄,默认NO
    self.cameraView.fixedFocusPoint = [userDefaults boolForKey:@"fixed_focus"];// 是否固定对焦位置,默认YES
    self.cameraView.fixedExposurePoint = [userDefaults boolForKey:@"fixed_exposure"];// 是否固定曝光位置,默认YES
    self.cameraView.shootAfterFocus = [userDefaults boolForKey:@"shoot_after_focus"];// 是否对焦后拍摄,默认NO
    self.cameraView.showPreviewLayer = [userDefaults boolForKey:@"show_preview"];// 是否显示预览图层,默认默认YES
    self.cameraView.targetResolution = CGSizeMake(40000, 30000);// 图像尺寸
    self.cameraView.savePicturesToLibrary = YES;// 保存到系统相册
    self.cameraView.targetLibraryAlbumName = @"HEIC";// 系统相册名称
    self.cameraView.animateLastPictureImageView = YES;// 拍照完成后图片有放入相册的动画效果
    self.cameraView.keepFrontCameraPicturesMirrored = YES;// 前置摄像头预览是否为镜像

    // 设置视频保存目录
    NSURL *_targetMovieFolder = [NSURL fileURLWithPath:[[NBUAssetUtils documentsDirectory] stringByAppendingPathComponent:NBUAssetUtils.VideoDirectory]];
    self.cameraView.targetMovieFolder = _targetMovieFolder;
    self.cameraView.captureMovieResultBlock = ^(NSURL *movieURL, NSError *error) {
        UIImage *Image = [NBUAssetUtils getScreenShotImageFromVideoPath:movieURL.path];
        [NBUAssetUtils saveVideo:Image toAlubm:NBUAssetUtils.VideoDirectory fileName:movieURL.lastPathComponent encodeType:0];
        NBULogInfo(@"保存到路径:%@", movieURL);
    };

    // 各种属性改变之后的回调
    self.cameraView.flashButtonConfigurationBlock = [self.cameraView buttonConfigurationBlockWithTitleFrom:@[@"关", @"开", @"自动"]];
    self.cameraView.focusButtonConfigurationBlock = [self.cameraView buttonConfigurationBlockWithTitleFrom:@[@"锁定对焦", @"自动对焦", @"连续对焦"]];
    self.cameraView.exposureButtonConfigurationBlock = [self.cameraView buttonConfigurationBlockWithTitleFrom:@[@"锁定曝光", @"自动曝光", @"连续曝光"]];
    self.cameraView.whiteBalanceButtonConfigurationBlock = [self.cameraView buttonConfigurationBlockWithTitleFrom:@[@"锁定白平衡", @"自动白平衡", @"连续白平衡"]];

    // 拍摄按钮事件
    self.cameraView.shootButton = _shootButton;
    [_shootButton addTarget:self.cameraView action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
    // 拍照(只处理了序列)后的回调
    self.cameraView.captureResultBlock = ^(NSData *data, UIImage *image, NSError *error) {
        if (!error && self.cameraView.currentOutPutType == NBUCameraOutPutModeTypeVideoData) {
            self.cameraView.lastPictureImageView.image = image;
        }
    };

    // 左下角图片点击事件
    [self.cameraView.lastPictureImageView setUserInteractionEnabled:YES];
    [self.cameraView.lastPictureImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openAlbum:)]];

    // 切换手势
    _rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [_rightGestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:_rightGestureRecognizer];

    _leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [_leftGestureRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:_leftGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    // 隐藏状态栏和标题栏
    [self changeStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // 第一次进入计算尺寸
    if (CGRectEqualToRect(_cameraFrame, CGRectZero)) {
        _cameraFrame = [self calculateCameraFrame:CGSizeZero];
        float x = (self.bottomContainer.size.width - self.views.size.width - self.video.size.width * 2) / 2;
        self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
        self.picture.textColor = [UIColor orangeColor];

    }
    // 尺寸改变更新布局
    if (!CGRectEqualToRect(self.cameraView.frame, _cameraFrame)) {
        self.cameraView.frame = _cameraFrame;
    }
}

#pragma mark 打开相册

- (void)openAlbum:(UITapGestureRecognizer *)sender {
    AlbumViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumViewController"];
    controller.onlyLoadDocument = NO;
    [self.navigationController pushViewController:controller animated:YES];
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

#pragma mark 计算当前目标分辨率对应的预览图布局属性

- (CGRect)calculateCameraFrame:(CGSize)size {
    //CGSize size =  self.cameraView.targetResolution;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = CGSizeMake(40000, 30000);
    }
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;// 屏幕尺寸包括状态栏
    CGSize cameraSize = [VideoViewController calculateCameraSize:size];//相机实际尺寸

    float offsetX = 0.0f;// x方向偏移
    float offsetY = 0.0f;// y方向偏移
    if (screenSize.width - cameraSize.width >= 0.01) {// 如果宽度不够屏幕宽度
        offsetX = (screenSize.width - cameraSize.width) / 2;
    } else {
        float height = screenSize.height - self.topContainer.frame.size.height - self.bottomContainer.frame.size.height;//空白区域高度
        if (height >= cameraSize.height) {// 如果空白区域高度大于相机高度,在空白区域中间显示
            offsetY = self.topContainer.frame.size.height; // (height - cameraSize.height) / 2 + self.topContainer.frame.size.height;
        } else {// 如果相机高度大于空白区域高度,那么使用屏幕高度计算偏移,进入到底部和顶部的高度相等
            offsetY = (screenSize.height - cameraSize.height) / 2;
        }
        NBULogInfo(@"空白区域高度%f", height);
    }
    CGRect rect = CGRectMake(offsetX, offsetY, cameraSize.width, cameraSize.height);

    NBULogInfo(@"offsetX:%f , offsetY:%f", offsetX, offsetY);
    NBULogInfo(@"顶部高度:%f", self.topContainer.frame.size.height);
    NBULogInfo(@"底部高度:%f", self.bottomContainer.frame.size.height);
    NBULogInfo(@"屏幕尺寸:%@", NSStringFromCGSize(screenSize));
    NBULogInfo(@"相机尺寸:%@", NSStringFromCGSize(cameraSize));
    NBULogInfo(@"布局属性:%@", NSStringFromCGRect(rect));

    return rect;
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizerRecognizer {
    [self toggle:recognizerRecognizer.direction];
}

- (void)toggle:(NSInteger)type {
    NBUCameraOutPutType targetOutputType = NBUCameraOutPutModeTypeImage;
    NSArray *_outTypes = self.cameraView.availableCameraOutTypes;
    if (type == UISwipeGestureRecognizerDirectionRight) {//向右滑动
        targetOutputType = (NBUCameraOutPutType) [[_outTypes objectBefore:@(self.cameraView.currentOutPutType)
                                                                     wrap:YES] integerValue];
    } else if (type == UISwipeGestureRecognizerDirectionLeft) {//向左滑动
        targetOutputType = (NBUCameraOutPutType) [[_outTypes objectAfter:@(self.cameraView.currentOutPutType)
                                                                    wrap:YES] integerValue];
    }
    CGSize targetResolution = CGSizeMake(40000, 30000);
    switch (targetOutputType) {
        case NBUCameraOutPutModeTypeImage: {//切换到图片
            targetResolution = CGSizeMake(40000, 30000);
            break;
        }
        case NBUCameraOutPutModeTypeVideo: {//切换到视频
            targetResolution = CGSizeMake(1280, 720);
            break;
        }
        case NBUCameraOutPutModeTypeVideoData: {//切换到序列
            targetResolution = CGSizeMake(1280, 720);
            break;
        }
    }

    _cameraFrame = [self calculateCameraFrame:targetResolution];

    [self.cameraView toggleCameraType:targetOutputType targetResolution:targetResolution targetFrame:_cameraFrame resultBlock:^(NBUCameraOutPutType outPutType, BOOL success) {
        if (!success)return;
        [self.views.layer removeAllAnimations];
        switch (outPutType) {
            case NBUCameraOutPutModeTypeImage: {//切换到图片
                self.videoData.textColor = [UIColor whiteColor];
                self.video.textColor = [UIColor whiteColor];
                self.picture.textColor = [UIColor orangeColor];
                float x = (self.bottomContainer.size.width - self.views.size.width - self.video.size.width * 2) / 2;
                [UIView transitionWithView:self.views
                                  duration:0.3
                                   options:UIViewAnimationOptionTransitionNone
                                animations:^() {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }
                                completion:^(BOOL finished) {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }];
                break;
            }
            case NBUCameraOutPutModeTypeVideo: {//切换到视频
                self.videoData.textColor = [UIColor whiteColor];
                self.video.textColor = [UIColor orangeColor];
                self.picture.textColor = [UIColor whiteColor];
                float x = (self.bottomContainer.size.width - self.views.size.width) / 2;
                [UIView transitionWithView:self.views
                                  duration:0.3
                                   options:UIViewAnimationOptionTransitionNone
                                animations:^() {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }
                                completion:^(BOOL finished) {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }];
                break;
            }
            case NBUCameraOutPutModeTypeVideoData: {//切换到序列
                self.videoData.textColor = [UIColor orangeColor];
                self.video.textColor = [UIColor whiteColor];
                self.picture.textColor = [UIColor whiteColor];
                float x = (self.bottomContainer.size.width - self.views.size.width + self.video.size.width * 2) / 2;
                [UIView transitionWithView:self.views
                                  duration:0.3
                                   options:UIViewAnimationOptionTransitionNone
                                animations:^() {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }
                                completion:^(BOOL finished) {
                                    self.views.frame = CGRectMake(x, 0, self.views.size.width, self.views.size.height);
                                }];
                break;
            }
        }
    }];
}

#pragma mark 根据设置的分辨率比例设置预览的尺寸 previewSize: 参数会被方法修改为 高度 > 宽度 如 {4, 3}将会转换为{3, 4}

+ (CGSize)calculateCameraSize:(CGSize)previewSize {
    // 保持手机竖直放置
    if (previewSize.width > previewSize.height) {
        previewSize = CGSizeMake(previewSize.height, previewSize.width);
    }
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;// 屏幕尺寸包括状态栏
    //显示播放器界面
    double screenWidth = screenSize.width;// 屏幕宽度
    double screenHeight = screenSize.height;//屏幕高度

    //首先取得相机的宽和高
    double cameraWidth = previewSize.width;//相机实际宽度
    double cameraHeight = previewSize.height;//相机实际高度

    double cameraRadio = cameraHeight / cameraWidth;//相机宽高比例
    double screenRadio = screenHeight / screenWidth;//屏幕宽高比例

    //计算照片,视频需要显示的宽高
    if (cameraRadio > screenRadio) {//如 3:1 > 1:1 表示宽度超过限制,设置高度为屏幕高度,然后以屏幕高度为基准计算高度即可
        cameraHeight = screenHeight;
        cameraWidth = (cameraHeight / cameraRadio);
    } else {//根据宽度计算
        cameraWidth = screenWidth;//设置相机宽度为最大屏幕宽度
        cameraHeight = (cameraWidth * cameraRadio);//计算相机高度
    }

    // 更新预览的尺寸
    CGSize cameraSize = CGSizeMake(cameraWidth, cameraHeight);
    return cameraSize;
}


@end
