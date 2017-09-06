//
//  NBUCameraViewController.m
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/11/12.
//  Copyright (c) 2012-2014 CyberAgent Inc.
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

#import <MediaPlayer/MediaPlayer.h>
#import "NBUCameraViewController.h"
#import "NBUImagePickerPrivate.h"
#import <RBVolumeButtons@PTEz/RBVolumeButtons.h>

/**
 *  默认的相机页面基类
 */
@implementation NBUCameraViewController {
    UITapGestureRecognizer *_tapGesture;
    RBVolumeButtons *_buttonStealer;
}

#pragma mark 相机是否可用

/**
 *  相机是否可用
 *
 *  @return 相机是否可用
 */
+ (BOOL)isCameraAvailable {
#if TARGET_IPHONE_SIMULATOR
    // 如果是模拟器返回 YES Simulator has a mock camera
    return YES;
#endif

    // Check with UIImagePickerController
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (void)commonInit {
    [super commonInit];
    // 使用音量键拍摄
    self.takesPicturesWithVolumeButtons = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure the camera view
    self.targetResolution = _targetResolution;
    self.captureResultBlock = _captureResultBlock;
    self.savePicturesToLibrary = _savePicturesToLibrary;
    self.targetLibraryAlbumName = _targetLibraryAlbumName;

    __weak NBUCameraViewController *weakSelf = self;
    // 闪光灯
    _cameraView.flashButtonConfigurationBlock = ^(id <UIButton> button, AVCaptureFlashMode mode) {
        weakSelf.flashLabel.hidden = button.hidden;
        switch (mode) {
            case AVCaptureFlashModeOn:
                weakSelf.flashLabel.text = @"开";
                break;

            case AVCaptureFlashModeOff:
                weakSelf.flashLabel.text = @"关";
                break;

            case AVCaptureFlashModeAuto:
            default:
                weakSelf.flashLabel.text = @"自动";
                break;
        }
    };

    // 对焦模式
    _cameraView.focusButtonConfigurationBlock = ^(id <UIButton> button, AVCaptureFocusMode mode) {
        weakSelf.focusLabel.hidden = button.hidden;
        switch (mode) {
            case AVCaptureFocusModeLocked:
                weakSelf.focusLabel.text = @"锁定焦点";
                break;
            case AVCaptureFocusModeAutoFocus:
                weakSelf.focusLabel.text = @"自动对焦";
                break;
            case AVCaptureFocusModeContinuousAutoFocus:
                weakSelf.focusLabel.text = @"连续自动对焦";
                break;
            default:
                break;
        }
    };

    // 曝光模式
    _cameraView.exposureButtonConfigurationBlock = ^(id <UIButton> button, AVCaptureExposureMode mode) {
        weakSelf.exposureLabel.hidden = button.hidden;
        switch (mode) {
            case AVCaptureExposureModeCustom:
                weakSelf.exposureLabel.text = @"自定义";
                break;
            case AVCaptureExposureModeLocked:
                weakSelf.exposureLabel.text = @"锁定";
                break;
            case AVCaptureExposureModeAutoExpose:
                weakSelf.exposureLabel.text = @"自动曝光";
                break;
            case AVCaptureExposureModeContinuousAutoExposure:
                weakSelf.exposureLabel.text = @"连续自动曝光";
                break;
            default:
                break;
        }
    };

    // 白平衡模式
    _cameraView.whiteBalanceButtonConfigurationBlock = ^(id <UIButton> button, AVCaptureWhiteBalanceMode mode) {
        weakSelf.whiteBalanceLabel.hidden = button.hidden;
        switch (mode) {
            case AVCaptureWhiteBalanceModeLocked:
                weakSelf.whiteBalanceLabel.text = @"锁定白平衡";
                break;
            case AVCaptureWhiteBalanceModeAutoWhiteBalance:
                weakSelf.whiteBalanceLabel.text = @"自动白平衡";
                break;
            case AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance:
                weakSelf.whiteBalanceLabel.text = @"连续自动白平衡";
                break;
            default:
                break;
        }

    };

    // Configure title
    if (!self.navigationItem.titleView && [self.navigationItem.title hasPrefix:@"@@"]) {
        if (!_cameraView.userDeniedAccess && !_cameraView.restrictedAccess) {
            self.navigationItem.title = NBULocalizedString(@"NBUImagePickerController CameraTitle", @"Camera");
        } else {
            self.navigationItem.title = NBULocalizedString(@"NBUImagePickerController CameraAccessDeniedTitle", @"Camera Access Denied");
        }
    }

    // Configure access denied view if needed
    if (_accessDeniedView) {
        _accessDeniedView.hidden = (!_cameraView.userDeniedAccess && !_cameraView.restrictedAccess);
        if (_accessDeniedView.hidden == NO) {
            _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handTap:)];
            [_accessDeniedView addGestureRecognizer:_tapGesture];
        } else {
            [_accessDeniedView removeGestureRecognizer:_tapGesture];
        }
    }
}

- (void)handTap:(UITapGestureRecognizer *)gesture {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)viewDidUnload {
    _cameraView = nil;

    [self setFlashLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Start stealing buttons
    if (_takesPicturesWithVolumeButtons) {
        if (!_buttonStealer) {
            __weak NBUCameraViewController *weakSelf = self;
            ButtonBlock block = ^{
                // 音量按钮点击时候不显示音量调节界面
                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                NSError *error = nil;
                if (audioSession.otherAudioPlaying) {
                    [audioSession setActive:NO error:&error];
                } else {
                    [audioSession setActive:YES error:&error];
                }
                [weakSelf.cameraView takePicture:weakSelf];
            };
            _buttonStealer = [RBVolumeButtons new];
            // 设置这句的原因是隐藏AirPlay按钮
            _buttonStealer.volumeView.frame = CGRectMake(0, -40, 1, 1);
            //[((MPVolumeView*)(_buttonStealer.volumeView)) setShowsVolumeSlider:NO];
            _buttonStealer.upBlock = block;
            _buttonStealer.downBlock = block;
        }

        [_buttonStealer startStealingVolumeButtonEvents];
    }
#if !TARGET_IPHONE_SIMULATOR
    if (self.cameraView.shootAfterFocus) {// 如果是对焦后拍摄,添加对焦后的监听
        NSKeyValueObservingOptions flags = NSKeyValueObservingOptionNew;
        AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [camDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
    }
#endif
}

// 对焦监听事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        BOOL adjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        NBULogInfo(@"Is adjusting focus? %@", adjustingFocus ? @"YES" : @"NO");
        if (!adjustingFocus) {// 对焦完成
            _cameraView.focusing = NO;
            if (_cameraView.shootAfterFocus) {// 如果是对焦后拍摄
                [_cameraView takePicture:self];
            }
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Stop stealing buttons
    if (_takesPicturesWithVolumeButtons) {
        [_buttonStealer stopStealingVolumeButtonEvents];
    }
#if !TARGET_IPHONE_SIMULATOR
    if (self.cameraView.shootAfterFocus) {// 移除对焦监听
        AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [camDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    }
#endif
}

#pragma mark - set方法重写

/**
 *  设置音量键是否用于拍摄
 *
 *  @param takesPicturesWithVolumeButtons 音量键是否用于拍摄
 */
#pragma mark 设置音量键是否用于拍摄

- (void)setTakesPicturesWithVolumeButtons:(BOOL)takesPicturesWithVolumeButtons {
    _takesPicturesWithVolumeButtons = takesPicturesWithVolumeButtons;
}

/**
 *  设置相片尺寸
 *
 *  @param targetResolution 相片尺寸
 */
#pragma mark 设置相片尺寸

- (void)setTargetResolution:(CGSize)targetResolution {
    _targetResolution = targetResolution;

    if (_cameraView) {
        _cameraView.targetResolution = targetResolution;
    }
}

/**
 *  设置拍摄完成后的回调方法
 *
 *  @param captureResultBlock 在NBUCameraView中定义的block
 */
#pragma mark 设置拍摄完成后的回调方法

- (void)setCaptureResultBlock:(NBUCapturePictureResultBlock)captureResultBlock {
    _captureResultBlock = captureResultBlock;

    if (_cameraView) {
        _cameraView.captureResultBlock = captureResultBlock;
    }
}
/**
 *  设置是否保存到相册
 *
 *  @param savePicturesToLibrary 是否保存到相册
 */
#pragma mark 设置是否保存到相册

- (void)setSavePicturesToLibrary:(BOOL)savePicturesToLibrary {
    _savePicturesToLibrary = savePicturesToLibrary;

    if (_cameraView) {
        _cameraView.savePicturesToLibrary = savePicturesToLibrary;
    }
}

/**
 *  设置照片保存的相册名称
 *
 *  @param targetLibraryAlbumName 保存相片的相册名称
 */
#pragma mark 设置照片保存的相册名称

- (void)setTargetLibraryAlbumName:(NSString *)targetLibraryAlbumName {
    _targetLibraryAlbumName = targetLibraryAlbumName;

    if (_cameraView) {
        _cameraView.targetLibraryAlbumName = targetLibraryAlbumName;
    }
}

@end

