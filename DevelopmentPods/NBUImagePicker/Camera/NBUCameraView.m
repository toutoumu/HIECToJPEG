//
//  NBUCameraView.m
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/10/15.
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

#import "NBUCameraView.h"
#import "NBUImagePickerPrivate.h"
#import "RKOrderedDictionary.h"
#import <MotionOrientation@PTEz/MotionOrientation.h>

// Class extension
@interface NBUCameraView () <AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CAAnimationDelegate>

@end

/**
 * 点击区域指示器 Private class
 */
@interface PointOfInterestView : UIView

@end


@implementation NBUCameraView {
    BOOL _canTake;//是否可以拍摄
    BOOL _focusing;//是否正在对焦
    BOOL _captureInProgress;//是否正在拍照
    BOOL _transitionAnimating;//是否正在执行动画
    NBUCameraOutPutType _outputType;//当前相机是拍照还是视频

    NSMutableArray *_controls;//控件集合
    PointOfInterestView *_poiView;//对焦区域

    AVCaptureDevice *_captureDevice;//当前的输入硬件,前置后置摄像头
    AVCaptureDeviceInput *_captureDeviceInput;// 当前的输入硬件对应的输入
    AVCaptureSession *_captureSession;
    AVCaptureConnection *_captureConnection;//输入输出链接
    AVCaptureMovieFileOutput *_captureMovieOutput;//视频文件输出
    AVCaptureVideoDataOutput *_captureVideoDataOutput;//视频数据输出
    AVCaptureStillImageOutput *_captureImageOutput;//图片输出
    AVCaptureVideoPreviewLayer *_previewLayer;//预览

    NSDate *_lastSequenceCaptureDate;//最后采集图像的时间
    UIImageOrientation _sequenceCaptureOrientation;//最后采集的图像的旋转方向

#if TARGET_IPHONE_SIMULATOR
    UIImage * _mockImage; // 为模拟器使用一张图片作为相机 Mock image for simulator
#endif
}

- (void)commonInit {
    [super commonInit];

    _canTake = NO;//是否可以拍摄
    _focusing = NO;//是否正在对焦
    _captureInProgress = NO;//是否正在拍照
    _transitionAnimating = NO;//是否正在执行动画
    _outputType = NBUCameraOutPutModeTypeImage;// 相机拍摄默认为图片

    self.fixedFocusPoint = NO;//是否固定对焦区域
    self.shootAfterFocus = NO;//是否触摸后拍摄
    self.showPreviewLayer = YES;//显示预览图层

    // Configure the view
    self.recognizeSwipe = NO;//是否启用滑动手势
    self.recognizeTap = YES;//是否启用敲击手势
    self.recognizeDoubleTap = YES;//是否启用双击手势
    self.doNotHighlightOnTap = YES;//敲击时候是否不高亮
    self.highlightColor = [UIColor colorWithWhite:1.0 alpha:0.7];//高亮颜色
    self.animateLastPictureImageView = YES;//拍照时最后一张相片是否显示动画效果

    _availableCameraOutTypes =[NSArray arrayWithArray:@[@(NBUCameraOutPutModeTypeVideoData), @(NBUCameraOutPutModeTypeVideo), @( NBUCameraOutPutModeTypeImage)]];


    _poiView = [PointOfInterestView new];// 点击位置(对焦区域)指示器 PoI view
    [self addSubview:_poiView];

    // First orientation update
    //[MotionOrientation initialize];
    [self setDeviceOrientation:[MotionOrientation sharedInstance].deviceOrientation];

#if TARGET_IPHONE_SIMULATOR
    {
        // 模拟器属性配置 Mock image for simulator
        _mockImage = [UIImage imageNamed:@"LaunchImage-700"] ?: [UIImage imageNamed:@"Default"]; // Try to use the App's launch image
        if (!_mockImage)
        {
            NBULogWarn(@"Couldn't load a mock image.");
        }
        UIImageView * mockView = [[UIImageView alloc] initWithImage:_mockImage];
        //mockView.contentMode = UIViewContentModeScaleToFill;
        //mockView.contentMode = UIViewContentModeScaleAspectFill;
        mockView.contentMode = UIViewContentModeScaleAspectFit;
        //[mockView setClipsToBounds:YES];
        mockView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mockView.frame = self.bounds;
        [self insertSubview:mockView atIndex:0];
    }
#endif
}

- (void)dealloc {

}


#if !TARGET_IPHONE_SIMULATOR

/**
 * 对焦监听回调方法
 * @param keyPath
 * @param object
 * @param change
 * @param context
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        BOOL adjustingFocus = [change[NSKeyValueChangeNewKey] isEqualToNumber:@1];
        if (!adjustingFocus && _shootAfterFocus && _canTake) {// 对焦完成,如果是对焦后拍摄,且可以拍摄
            _canTake = NO;
            _focusing = NO;
            [self takePicture:self];
        }
    }
}

#endif

/**
 * 添加监听
 */
- (void)addObserver {
    // 手机方向改变监听 Observe orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationChanged:)
                                                 name:MotionOrientationChangedNotification
                                               object:nil];

#if !TARGET_IPHONE_SIMULATOR
    if (_shootAfterFocus) {// 如果是对焦后拍摄,添加对焦后的监听
        [_captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    }
#endif
}

/**
 * 移除监听
 */
- (void)removeObserver {
    // 停止手机方向改变监听 Stop observing
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if !TARGET_IPHONE_SIMULATOR
    if (_shootAfterFocus) {// 移除对焦监听
        [_captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    }
#endif
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_previewLayer) {
        _previewLayer.frame = self.layer.bounds;
    }
#if TARGET_IPHONE_SIMULATOR
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[UIImage class]]) {
            v.frame = self.bounds;
            break;
        }
    }
#endif
}

- (void)viewWillAppear {
    [super viewWillAppear];

    // 将各种页面控件缓存到列表中 Gather the available UI controls
    if (!_controls) {
        _controls = [NSMutableArray array];
        if (_toggleCameraButton) [_controls addObject:_toggleCameraButton];
        if (_flashButton) [_controls addObject:_flashButton];
        if (_focusButton) [_controls addObject:_focusButton];
        if (_exposureButton) [_controls addObject:_exposureButton];
        if (_whiteBalanceButton) [_controls addObject:_whiteBalanceButton];
    }

    // 权限判断 Access denied?
    if (self.userDeniedAccess || self.restrictedAccess) {
        NBULogWarn(@"Access to camera denied");
        [self updateUI];
        return;
    }

    // 创建session Create a capture session if needed
    if (!_captureSession) {
        _captureSession = [AVCaptureSession new];
    }

    // 创建预览视图 Create the preview layer
    if (!_previewLayer && self.showPreviewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; //AVLayerVideoGravityResizeAspect;
        _previewLayer.frame = self.layer.bounds;
        [self.layer insertSublayer:_previewLayer atIndex:0];
    }

    // 图片输出,由于进入相机第一次使用的是捕获图片因此... Configure output if needed
    if (!_captureImageOutput) {
        if (![self updateOutput:NBUCameraOutPutModeTypeImage targetResolution:self.targetResolution]) {
            return;
        }
    }

    // 图像输入设备 Get a capture device if needed
    if (!_captureDevice && !_availableCaptureDevices) {
#if !TARGET_IPHONE_SIMULATOR // 真机的输入设备 Real devices
        self.currentAVCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
#else
        self.currentAVCaptureDevice = nil; // 模拟器输入设备 Simulator
#endif
    }

    [self addObserver];
    _shootButton.enabled = YES;

    // 开始运行 Start session if needed
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_captureSession.running) {
            [_captureSession startRunning];
            NBULogVerbose(@"Capture session: {\n%@} started running", _captureSession);
        }
    });
}

- (void)viewWillDisappear {
    [super viewWillDisappear];

    [self removeObserver];
    _shootButton.enabled = NO;

    // 停止运行 Stop session if possible
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (_captureSession.running && !_captureInProgress) {
            [_captureSession stopRunning];
            NBULogVerbose(@"Capture session: {\n%@} stopped running", _captureSession);
        }
    });
}

#pragma mark - Handle orientation changes

- (void)setFrame:(CGRect)frame {
    super.frame = frame;

    // Resize the preview layer as well
    // _previewLayer.frame = self.layer.bounds;
}

#pragma mark 设备方向改变监听

/**
 * 设备方向改变调用此方法
 * @discussion 这里得到的是设备的旋转方向(UIDeviceOrientation),
 *             但是对于摄像头来说有几个值是不需要的(UIDeviceOrientationFaceUp,UIDeviceOrientationFaceDown)
 *
 * @param notification
 */
- (void)deviceOrientationChanged:(NSNotification *)notification {
    [self setDeviceOrientation:[MotionOrientation sharedInstance].deviceOrientation];
}

- (void)setDeviceOrientation:(UIDeviceOrientation)orientation {
    if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
        [self setInterfaceOrientation:UIInterfaceOrientationFromValidDeviceOrientation(orientation)];
    }
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // Update video orientation
    if (_captureConnection.isVideoOrientationSupported) {
        _captureConnection.videoOrientation = (AVCaptureVideoOrientation) orientation;
    }

    // Also rotate view?
    if (_shouldAutoRotateView) {
        // Angle to rotate
        CGFloat angle;
        switch (orientation) {
            case UIInterfaceOrientationLandscapeRight:
                angle = (CGFloat) (-M_PI / 2.0);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                angle = (CGFloat) (M_PI / 2.0);
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                angle = (CGFloat) M_PI;
                break;
            case UIInterfaceOrientationPortrait:
            default:
                angle = 0;
                break;
        }

        // Flip height and width?
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            _previewLayer.bounds = CGRectMake(0.0, 0.0, self.layer.bounds.size.height, self.layer.bounds.size.width);
        }
            // Just resize for portrait
        else {
            _previewLayer.bounds = CGRectMake(0.0, 0.0, self.layer.bounds.size.width, self.layer.bounds.size.height);
        }

        // Rotate
        _previewLayer.transform = CATransform3DRotate(CATransform3DIdentity, angle, 0.0, 0.0, 1.0);

        // Reposition
        _previewLayer.position = CGPointMake((CGFloat) (self.layer.bounds.size.width / 2.0), (CGFloat) (self.layer.bounds.size.height / 2.0));

        NBULogVerbose(@"%@ anchorPoint: %@ position: %@ frame: %@ bounds: %@",
                THIS_METHOD,
                NSStringFromCGPoint(_previewLayer.anchorPoint),
                NSStringFromCGPoint(_previewLayer.position),
                NSStringFromCGRect(_previewLayer.frame),
                NSStringFromCGRect(_previewLayer.bounds));
    }
}

#pragma mark - Access permissions

- (BOOL)userDeniedAccess {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied;
}

- (BOOL)restrictedAccess {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusRestricted;
}

#pragma mark - Properties

- (NBUCameraOutPutType)currentOutPutType {
    return _outputType;
}

- (void)setCurrentCaptureDevice:(NSString *)currentCaptureDevice {
    self.currentAVCaptureDevice = [AVCaptureDevice deviceWithUniqueID:currentCaptureDevice];
}

- (NSString *)currentCaptureDevice {
    return _captureDevice.uniqueID;
}

- (void)setCurrentAVCaptureDevice:(AVCaptureDevice *)device {
    if ([_captureDevice.uniqueID isEqualToString:device.uniqueID])
        return;

    NBULogVerbose(@"%@: %@", THIS_METHOD, device);
    _captureDevice = device;

    // 可用的输入设备,前置摄像头,后置摄像头等 Other available devices
    NSMutableArray *tmp = [NSMutableArray array];
#if !TARGET_IPHONE_SIMULATOR
    for (AVCaptureDevice *other in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        [tmp addObject:other.uniqueID];
    }
#endif
    _availableCaptureDevices = [NSArray arrayWithArray:tmp];
    NBULogVerbose(@"availableCaptureDevices: %@", _availableCaptureDevices);

    // 可用的闪光灯模式 Available flash modes
    [tmp removeAllObjects];
    if ([_captureDevice isFlashModeSupported:AVCaptureFlashModeOff])
        [tmp addObject:@(AVCaptureFlashModeOff)];
    if ([_captureDevice isFlashModeSupported:AVCaptureFlashModeOn])
        [tmp addObject:@(AVCaptureFlashModeOn)];
    if ([_captureDevice isFlashModeSupported:AVCaptureFlashModeAuto])
        [tmp addObject:@(AVCaptureFlashModeAuto)];
    _availableFlashModes = [NSArray arrayWithArray:tmp];
    NBULogVerbose(@"availableFlashModes: %@", _availableFlashModes);

    // 可用的对焦模式 Available focus modes
    [tmp removeAllObjects];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeLocked])
        [tmp addObject:@(AVCaptureFocusModeLocked)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        [tmp addObject:@(AVCaptureFocusModeAutoFocus)];
    if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        [tmp addObject:@(AVCaptureFocusModeContinuousAutoFocus)];
    _availableFocusModes = [NSArray arrayWithArray:tmp];
    NBULogVerbose(@"availableFocusModes: %@", _availableFocusModes);

    // 可用的曝光模式 Available exposure modes
    [tmp removeAllObjects];
    if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeLocked])
        [tmp addObject:@(AVCaptureExposureModeLocked)];
    if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose])
        [tmp addObject:@(AVCaptureExposureModeAutoExpose)];
    if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        [tmp addObject:@(AVCaptureExposureModeContinuousAutoExposure)];
    _availableExposureModes = [NSArray arrayWithArray:tmp];
    NBULogVerbose(@"availableExposureModes: %@", _availableExposureModes);

    // 可用的白平衡模式 Available white balance modes
    [tmp removeAllObjects];
    if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked])
        [tmp addObject:@(AVCaptureWhiteBalanceModeLocked)];
    if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance])
        [tmp addObject:@(AVCaptureWhiteBalanceModeAutoWhiteBalance)];
    if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        [tmp addObject:@(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance)];
    _availableWhiteBalanceModes = [NSArray arrayWithArray:tmp];
    NBULogVerbose(@"availableWhiteBalanceModes: %@", _availableWhiteBalanceModes);

    // Update UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });

#if !TARGET_IPHONE_SIMULATOR
    // Update capture session
    [self updateCaptureSessionInput];
#endif
}

- (void)updateUI {
    // Enable/disable controls
    BOOL accessDenied = self.userDeniedAccess || self.restrictedAccess;
    _toggleCameraButton.enabled = !accessDenied && _availableCaptureDevices.count > 1;
    _flashButton.enabled = !accessDenied && _availableFlashModes.count > 1;
    _focusButton.enabled = !accessDenied && _availableFocusModes.count > 1;
    _exposureButton.enabled = !accessDenied && _availableExposureModes.count > 1;
    _whiteBalanceButton.enabled = !accessDenied && _availableWhiteBalanceModes.count > 1;
    _shootButton.enabled = !accessDenied;

    // Hide disabled controls?
    if (!_showDisabledControls) {
        for (id <UIButton> button in _controls) {
            if ([button isKindOfClass:[UIView class]]) {
                ((UIView *) button).hidden = !button.enabled;
            }
        }
    }

    // Apply configuration blocks
    if (_toggleCameraButtonConfigurationBlock)
        _toggleCameraButtonConfigurationBlock(_toggleCameraButton, _captureDevice.position);
    if (_flashButtonConfigurationBlock)
        _flashButtonConfigurationBlock(_flashButton, _captureDevice.flashMode);
    if (_focusButtonConfigurationBlock)
        _focusButtonConfigurationBlock(_focusButton, _captureDevice.focusMode);
    if (_exposureButtonConfigurationBlock)
        _exposureButtonConfigurationBlock(_exposureButton, _captureDevice.exposureMode);
    if (_whiteBalanceButtonConfigurationBlock)
        _whiteBalanceButtonConfigurationBlock(_whiteBalanceButton, _captureDevice.whiteBalanceMode);
}

- (NBUButtonConfigurationBlock)buttonConfigurationBlockWithTitleFormat:(NSString *)format {
    return ^(id <UIButton> button, NSInteger mode) {
        button.title = [NSString stringWithFormat:format, mode];
    };
}

- (NBUButtonConfigurationBlock)buttonConfigurationBlockWithTitleFrom:(NSArray *)titles {
    return ^(id <UIButton> button, NSInteger mode) {
        button.title = titles[mode];
    };
}

#pragma mark 更新输入, 只有当输入设备更改, 如前置摄像头, 切换为后置摄像头, 才需要调用此方法

- (void)updateCaptureSessionInput {
    [_captureSession beginConfiguration];

    // Remove previous input
    [_captureSession removeInput:_captureDeviceInput];

    // Create a capture input
    NSError *error;
    _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    if (error) {
        NBULogError(@"Error creating an AVCaptureDeviceInput: %@", error);
    }

    // 设置最佳分辨率 Choose the best suited session presset
    [_captureSession setSessionPreset:[self bestSuitedSessionPresetForResolution:_targetResolution]];

    // Add input to session
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        NBULogVerbose(@"Input: %@", _captureDeviceInput);
    } else {
        NBULogError(@"Can't add input: %@ to session: %@", _captureDeviceInput, _captureSession);
    }

    // 更新输入输出连接 Refresh the video connection
    [self updateConnection:_outputType];

    [_captureSession commitConfiguration];
}

/**
 *  获取最佳匹配的图片分辨率
 *
 *  @param targetResolution 期望的分辨率
 *
 *  @return 最佳匹配的分辨率
 */
- (NSString *)bestSuitedSessionPresetForResolution:(CGSize)targetResolution {
    // 如果没有设置分辨率,返回全尺寸,但这个尺寸不支持视频拍摄,所以视频拍摄必须指定这个值 Not set?
    if (CGSizeEqualToSize(targetResolution, CGSizeZero)) {
        NBULogInfo(@"No target resolution was set. Capturing full resolution pictures ('%@').", AVCaptureSessionPresetPhoto);
        return AVCaptureSessionPresetPhoto;
    }

    // 如果宽度小于高度,那么宽高对调 Make sure to have a portrait size
    CGSize target = targetResolution.width >= targetResolution.height ? targetResolution : CGSizeMake(targetResolution.height, targetResolution.width);
    // Try different resolutions
    NSString *preset;
    NSDictionary *resolutions = [self availableResolutionsForCurrentDevice];
    CGSize resolution;
    for (preset in resolutions) {
        resolution = [(NSValue *) resolutions[preset] CGSizeValue];
        if (resolution.width >= target.width && resolution.height >= target.height) {
            break;
        }
    }

    NBULogInfo(@"Best preset for target resolution %@ is '%@'", NSStringFromCGSize(target), preset);
    return preset;
}

#define sizeObject(width, height) [NSValue valueWithCGSize:CGSizeMake(width, height)]

/**
 *  获取可用的图片分辨率尺寸
 *
 *  @return 所以图片分辨率尺寸字典
 */
- (NSDictionary *)availableResolutionsForCurrentDevice {
    // Possible resolutions
    NSArray *presets;
    NSDictionary *possibleResolutions;
    presets = @[AVCaptureSessionPresetLow,
            AVCaptureSessionPreset352x288,
            AVCaptureSessionPresetMedium,
            AVCaptureSessionPreset640x480,
            AVCaptureSessionPresetiFrame960x540,
            AVCaptureSessionPreset1280x720,
            AVCaptureSessionPreset1920x1080,
            //AVCaptureSessionPreset3840x2160,//新加的(UHD 4K)
            AVCaptureSessionPresetPhoto];
    possibleResolutions = @{
            AVCaptureSessionPresetLow: sizeObject(192.0, 144.0),             // iOS4+
            AVCaptureSessionPreset352x288: sizeObject(352.0, 288.0),             // iOS5+
            AVCaptureSessionPresetMedium: sizeObject(480.0, 360.0),             // iOS4+,
            AVCaptureSessionPreset640x480: sizeObject(640.0, 480.0),             // iOS4+
            AVCaptureSessionPresetiFrame960x540: sizeObject(960.0, 540.0),             // iOS5+
            AVCaptureSessionPreset1280x720: sizeObject(1280.0, 720.0),            // iOS4+
            AVCaptureSessionPreset1920x1080: sizeObject(1920.0, 1080.0),           // iOS5+
            //AVCaptureSessionPreset3840x2160: sizeObject(3840.0, 2160.0),           // iOS5+
            AVCaptureSessionPresetPhoto: sizeObject(CGFLOAT_MAX, CGFLOAT_MAX)};// iOS4+, Full resolution

    // Resolutions available for the current device
    RKOrderedDictionary *availableResolutions = [RKOrderedDictionary dictionary];
    for (NSString *preset in presets) {
        if ([_captureDevice supportsAVCaptureSessionPreset:preset]) {
            availableResolutions[preset] = possibleResolutions[preset];
        }
    }
    NBULogVerbose(@"Available resolutions for %@: %@", _captureDevice, availableResolutions);

    return availableResolutions;
}

#pragma mark - Actions
#pragma mark 拍摄照片

- (void)takePicture:(id)sender {
    NBULogTrace();

    // 如果不允许访问相机返回
    if (self.userDeniedAccess || self.restrictedAccess) {
        NBULogWarn(@"%@ Aborted, camera access denied.", THIS_METHOD);
        return;
    }

    // 如果正在拍摄返回,Ignore?
    if (_captureInProgress || _focusing) {
        NBULogWarn(@"%@ Ignored as a capture is already in progress.", THIS_METHOD);
        return;
    }

    // 当拍照太快,在前端设置拍照间隔为n秒,等待数据处理完成之后再执行拍照 Skip capture?
    if ([[NSDate date] timeIntervalSinceDate:_lastSequenceCaptureDate] < _sequenceCaptureInterval) {
        return;
    }
    _sequenceCaptureInterval = 0.25; //最小拍照间隔恢复为默认值
    _lastSequenceCaptureDate = [NSDate date];//更新最后拍摄时间

    _captureInProgress = YES;// 设置为正在拍摄
    _shootButton.enabled = NO;// 禁用拍摄按钮 Update UI
    // [self flashHighlightMask];// 拍摄界面闪一下
// 如果是手机(真机)
#if !TARGET_IPHONE_SIMULATOR
    // 如果手机旋转方向有改变那么重新设置对焦信息
    static AVCaptureVideoOrientation preOrientation = 0;//之前的旋转方向
    AVCaptureVideoOrientation currentOrientation = _captureConnection.videoOrientation;//当前的旋转方向
    // 如果是固定对焦位置, 且不是对焦后拍摄(对焦后拍摄的对焦位置在点击的时候就已经设置了),且设置前后参数有变更
    if (self.fixedFocusPoint && !self.shootAfterFocus && preOrientation != currentOrientation) {
        if ((preOrientation == AVCaptureVideoOrientationLandscapeRight && currentOrientation == AVCaptureVideoOrientationLandscapeLeft) ||
                (preOrientation == AVCaptureVideoOrientationLandscapeLeft && currentOrientation == AVCaptureVideoOrientationLandscapeRight)) {
            preOrientation = currentOrientation;
            return;
        }

        preOrientation = currentOrientation;
        [self updateDeviceConfigurationWithBlock:^() {
            // 调整对焦位置, 手机竖直放置 横向为y 纵向为x 原点在右上角(注意是右上角,不是左上角)
            CGPoint pointOfInterest = CGPointMake(0.725, 0.5);
            switch (currentOrientation) {
                case AVCaptureVideoOrientationPortrait:
                    pointOfInterest = CGPointMake(0.725, 0.5);
                    break;
                case AVCaptureVideoOrientationLandscapeLeft:
                case AVCaptureVideoOrientationLandscapeRight:
                    pointOfInterest = CGPointMake(0.5, 0.5);
                    break;
                case AVCaptureVideoOrientationPortraitUpsideDown:
                    pointOfInterest = CGPointMake(0.275, 0.5);
                    break;
                default:
                    pointOfInterest = CGPointMake(0.725, 0.5);
                    break;
            }

            // [对焦位置设置]
            if (_captureDevice.isFocusPointOfInterestSupported) {
                _captureDevice.focusPointOfInterest = pointOfInterest;
            }
            //[曝光位置设置]
            if (_captureDevice.isExposurePointOfInterestSupported) {
                _captureDevice.exposurePointOfInterest = pointOfInterest;
            }
            // [对焦模式设置] 设置循环自动对焦
            if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                _captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }
            //[曝光模式设置] 设置循环自动曝光
            if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                _captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }
            //[白平衡设置] 设置循环白平衡设置
            if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                _captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
        }];
    }

    // 异步捕获图片 Get the image
    [_captureImageOutput captureStillImageAsynchronouslyFromConnection:_captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        _captureInProgress = NO;// 设置为拍摄完成

        // 如果窗口不存在停止 Stop session if needed
        if (!self.window && _captureSession.running) {
            [_captureSession stopRunning];
            NBULogVerbose(@"Capture session: {\n%@} stopped running", _captureSession);
        }

        if (error) {// 拍摄出错了
            NBULogError(@"Error: %@", error);
            _shootButton.enabled = YES;

            // 回调 Execute result blocks
            if (_captureResultBlock) _captureResultBlock(nil, error);
            if (_savePicturesToLibrary && _saveResultBlock) _saveResultBlock(nil, nil, nil, error);

            return;
        } else {// 处理图片数据
            UIImage *image = [UIImage imageWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer]];
            NBULogInfo(@"Captured jpeg image: %@ of size: %@ orientation: %@", image, NSStringFromCGSize(image.size), @(image.imageOrientation));
#else
            // Mock simulator
            _captureInProgress = NO;
            UIImage * image = _mockImage;
            NBULogInfo(@"Captured mock image: %@ of size: %@", image, NSStringFromCGSize(_mockImage.size));
#endif
            // 更新最后拍摄的哪一张照片显示 Update last picture view
            if (_lastPictureImageView) {
                //image = [image imageWithOrientationUp];//旋转到正确的方向
                if (_animateLastPictureImageView) {
                    static UIImageView *preview;// 定义在方法体里面的static变量只能在对应的访问里面访问，变量是类变量
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        preview = [[NBURotatingImageView alloc] initWithImage:image];
                        preview.contentMode = UIViewContentModeScaleAspectFill;
                        preview.clipsToBounds = YES;
                        [self.viewController.view addSubview:preview];
                    });
                    preview.image = image;
                    preview.hidden = NO;
                    preview.frame = [self.viewController.view convertRect:self.bounds fromView:self];

                    // Update UI
                    [UIView animateWithDuration:0.2
                                          delay:0.0
                                        options:UIViewAnimationOptionCurveEaseIn
                                     animations:^{
                                         preview.frame = [self.viewController.view convertRect:_lastPictureImageView.bounds fromView:_lastPictureImageView];
                                     }
                                     completion:^(BOOL finished) {
                                         //_lastPictureImageView.image = image;
                                         _lastPictureImageView.image = [image thumbnailWithSize:_lastPictureImageView.size];
                                         preview.hidden = YES;
                                         _shootButton.enabled = YES;

                                     }];
                }// End of if (_animateLastPictureImageView)
                else {
                    //_lastPictureImageView.image = image;
                    _lastPictureImageView.image = [image thumbnailWithSize:_lastPictureImageView.size];
                    _shootButton.enabled = YES;
                }
            }// End of if (_lastPictureImageView)
            else {
                _shootButton.enabled = YES;
            }

            // 拍照完成之后的回调方法 Execute capture block
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                if (_captureResultBlock) _captureResultBlock(image, nil);
            });

            // 如果不保存到相册 返回 No need to save image?
            if (!_savePicturesToLibrary)
                return;

            // Retrieve the metadata
            NSDictionary *metadata;
#if !TARGET_IPHONE_SIMULATOR
            metadata = (__bridge_transfer NSDictionary *) CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
            NBULogVerbose(@"Image metadata: %@", metadata);
#endif
            // 保存图片到相册
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                // Read metadata
                // 保存到系统相册 Save to the Camera Roll
                [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll:image
                                                               metadata:metadata
                                               addToAssetsGroupWithName:_targetLibraryAlbumName
                                                            resultBlock:^(NSURL *assetURL, NSError *saveError) {
                                                                // 保存之后的回调 Execute result block
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    if (_saveResultBlock) _saveResultBlock(image, metadata, assetURL, saveError);
                                                                });
                                                            }];
            });
#if !TARGET_IPHONE_SIMULATOR
        }
    }];
#endif
}// End of takePicture

- (IBAction)startStopPictureSequence:(id)sender {
    //更改拍摄按钮的选择状态,更改图标
    if (self.shootButton) {
        UIButton *shootBtn = ((UIButton *) self.shootButton);
        shootBtn.selected = !_capturingSequence;
    }
    if (!_capturingSequence) {
        [_captureSession removeOutput:_captureImageOutput];
        [_captureSession removeOutput:_captureMovieOutput];
        if (!_captureVideoDataOutput) {
            _captureVideoDataOutput = [AVCaptureVideoDataOutput new];
            _captureVideoDataOutput.videoSettings = @{(NSString *) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            [_captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
            if (_sequenceCaptureInterval == 0) {
                _sequenceCaptureInterval = 0.25;
            }
        }

        if ([_captureSession canAddOutput:_captureVideoDataOutput]) {
            [_captureSession addOutput:_captureVideoDataOutput];
            _lastSequenceCaptureDate = [NSDate date]; // Skip the first image which looks to dark for some reason
            _sequenceCaptureOrientation = (_captureDevice.position == AVCaptureDevicePositionFront ? // Set the output orientation only once per sequence
                    UIImageOrientationLeftMirrored :
                    UIImageOrientationRight);
            _capturingSequence = YES;
        } else {
            NBULogError(@"Can't capture picture sequences here!");
            return;
        }
    } else {
        [_captureSession removeOutput:_captureVideoDataOutput];
        _capturingSequence = NO;
    }
}

#pragma mark 视频录制时候数据流回调

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    // Skip capture?
    if ([[NSDate date] timeIntervalSinceDate:_lastSequenceCaptureDate] < _sequenceCaptureInterval)
        return;

    _lastSequenceCaptureDate = [NSDate date];

    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    NBULogInfo(@"Captured image: %@ of size: %@ orientation: %@", image, NSStringFromCGSize(image.size), @(image.imageOrientation));

    // 图片生成后的回调 Execute capture block
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_captureResultBlock) _captureResultBlock(image, nil);
    });
}

- (BOOL)isRecording {
    return _captureMovieOutput.recording;
}

- (IBAction)startStopRecording:(id)sender {
    //更改拍摄按钮的选择状态,更改图标
    if (self.shootButton) {
        UIButton *shootBtn = ((UIButton *) self.shootButton);
        shootBtn.selected = !self.recording;
    }

    if (!self.recording) {
#if !TARGET_IPHONE_SIMULATOR
        // 设置输出文件名称
        if (!_targetMovieFolder) {
            _targetMovieFolder = [UIApplication sharedApplication].documentsDirectory;
        }
        UInt64 recordTime = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
        NSString *name = [NSString stringWithFormat:@"%llu%@", recordTime, @"_%03d.mov"];
        NSURL *movieOutputURL = [NSFileManager URLForNewFileAtDirectory:_targetMovieFolder fileNameWithFormat:name];

        [_captureMovieOutput startRecordingToOutputFileURL:movieOutputURL recordingDelegate:self];// 设置输出和回调
#else
        NBULogInfo(@"No mock video recording on Simulator");
#endif
    } else {
        [_captureMovieOutput stopRecording];
    }
}

#pragma mark 视频录制之后的回调方法

- (void)              captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                    fromConnections:(NSArray *)connections
                              error:(NSError *)error {
    if (!error) {
        NBULogInfo(@"Finished capturing movie to %@", outputFileURL);
    } else {
        NBULogError(@"Error capturing movie: %@", error);
    }

    //[_captureSession removeOutput:_captureMovieOutput];
    if (_captureMovieResultBlock) _captureMovieResultBlock(outputFileURL, error);
}

#pragma mark targetResolution 目标分辨率 targetFrame CameraView的Frame属性

- (void)toggleCameraType:(NBUCameraOutPutType)targetOutputType targetResolution:(CGSize)targetResolution targetFrame:(CGRect)targetFrame resultBlock:(void (^)(NBUCameraOutPutType, BOOL))callback {
    // 是否正在 拍照,拍摄,对焦
    if (_captureInProgress || _focusing || [self isRecording] || _capturingSequence) {
        if (callback) {
            callback(_outputType, NO);
        }
        return;
    }

    //操作队列
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    });
    [queue cancelAllOperations];// 取消未执行的操作

    __block UIView *maskView = nil;//遮罩层

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.maskViewContainer) {//如果设置了切换遮罩
            // 移除掉之前添加的遮罩,和动画
            for (UIView *view in self.maskViewContainer.subviews) {
                if (![view isMemberOfClass:NBUCameraView.class]) {
                    [view.layer removeAllAnimations];
                    [view removeFromSuperview];
                }
            }

            // 生成遮罩层 --- 这里需要判断设备是否支持模糊效果 http://stackoverflow.com/a/29997626/2269387
            CGRect maskFrame = self.frame;
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
            UIView *tempView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            tempView.frame = CGRectMake(0, 0, maskFrame.size.width, maskFrame.size.height);// 遮罩层必须填充满整个CameraView
            [self insertSubview:tempView atIndex:(NSInteger) ([_previewLayer zPosition] + 1)];

            maskView = [self snapshotViewAfterScreenUpdates:YES];
            maskView.frame = maskFrame; // 遮罩层的布局应该是完全覆盖CameraView,即位置尺寸和CameraView相同
            [self.maskViewContainer addSubview:maskView];
            [tempView removeFromSuperview];

            _previewLayer.opacity = 0.0;//隐藏预览层
        }

        if (_shootButton) _shootButton.enabled = NO;
        if (_toggleCameraButton) _toggleCameraButton.enabled = NO;
        self.frame = targetFrame;//更新相机布局
        self.targetResolution = targetResolution;//更新分辨率期望值
        _outputType = targetOutputType;// 由于有可能这段代码执行的线程和调用方法的线程不一致,因此需要临时保存这个值

        if (callback) {// 回调
            callback(targetOutputType, YES);
        }
        // 更新界面UI
        switch (_outputType) {
            case NBUCameraOutPutModeTypeVideo: {//切换到视频
                if (self.shootButton) {
                    UIButton *shootBtn = ((UIButton *) self.shootButton);
                    shootBtn.selected = NO;
                    [shootBtn setImage:[UIImage imageNamed:@"videoStart"] forState:UIControlStateNormal];
                    [shootBtn setImage:[UIImage imageNamed:@"videoStop"] forState:UIControlStateSelected];
                    [shootBtn removeTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn removeTarget:self action:@selector(startStopPictureSequence:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn addTarget:self action:@selector(startStopRecording:) forControlEvents:UIControlEventTouchUpInside];
                }
                break;
            }
            case NBUCameraOutPutModeTypeImage: {//切换到照片
                if (self.shootButton) {
                    UIButton *shootBtn = ((UIButton *) self.shootButton);
                    shootBtn.selected = NO;
                    [shootBtn setImage:[UIImage imageNamed:@"cameraButton"] forState:UIControlStateNormal];
                    [shootBtn setImage:[UIImage imageNamed:@"cameraButton"] forState:UIControlStateSelected];
                    [shootBtn removeTarget:self action:@selector(startStopRecording:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn removeTarget:self action:@selector(startStopPictureSequence:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn addTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
                }
                break;
            }
            case NBUCameraOutPutModeTypeVideoData: {
                if (self.shootButton) {
                    UIButton *shootBtn = ((UIButton *) self.shootButton);
                    shootBtn.selected = NO;
                    [shootBtn setImage:[UIImage imageNamed:@"videoStart"] forState:UIControlStateNormal];
                    [shootBtn setImage:[UIImage imageNamed:@"videoStop"] forState:UIControlStateSelected];
                    [shootBtn removeTarget:self action:@selector(takePicture:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn removeTarget:self action:@selector(startStopRecording:) forControlEvents:UIControlEventTouchUpInside];
                    [shootBtn addTarget:self action:@selector(startStopPictureSequence:) forControlEvents:UIControlEventTouchUpInside];
                }
                break;
            }
        }
    });

    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [_captureSession beginConfiguration];
        // 更新输出
        [self updateOutput:targetOutputType targetResolution:targetResolution];
        // 更新输入输出连接
        [self updateConnection:targetOutputType];
        [_captureSession commitConfiguration];
        // 更新相机参数

        if (self.maskViewContainer) {// 执行完成动画
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionAllowUserInteraction
                                 animations:^() {
                                     maskView.frame = targetFrame;
                                     maskView.alpha = 0.5;
                                 } completion:^(BOOL finish) {
                            if (finish) {
                                if (_shootButton) _shootButton.enabled = YES;
                                if (_toggleCameraButton)_toggleCameraButton.enabled = YES;
                                _previewLayer.opacity = 1.0;
                                [maskView removeFromSuperview];
                            }
                        }
                ];
            });
        }
    }];
    [queue addOperation:operation];
}

- (void)animationDidStart:(CAAnimation *)anim {
    _previewLayer.opacity = 0.0;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    _previewLayer.opacity = 1.0;
}

#pragma mark 更新输出

- (BOOL)updateOutput:(NBUCameraOutPutType)outPutType targetResolution:(CGSize)resolution {
    switch (outPutType) {
        case NBUCameraOutPutModeTypeImage : {//切换到拍照
            // 移除视频输出
            [_captureSession removeOutput:_captureMovieOutput];
            [_captureSession removeOutput:_captureVideoDataOutput];

            // 设置新的输出
            if (!_captureImageOutput) {
                _captureImageOutput = [AVCaptureStillImageOutput new];
            }
            if ([_captureSession canAddOutput:_captureImageOutput]) {
                if (_captureSession.isRunning) {
                    [_captureSession setSessionPreset:[self bestSuitedSessionPresetForResolution:resolution]];
                }
                [_captureSession addOutput:_captureImageOutput];
            } else {
                NBULogError(@"Can't add output: %@ to session: %@", _captureImageOutput, _captureSession);
                return NO;
            }
            NBULogVerbose(@"Output: %@ settings: %@", _captureImageOutput, _captureImageOutput.outputSettings);
            break;
        }
        case NBUCameraOutPutModeTypeVideo : {//切换到视频
            // 移除图片输出
            [_captureSession removeOutput:_captureImageOutput];
            [_captureSession removeOutput:_captureVideoDataOutput];

            // 设置新的输出
            if (!_captureMovieOutput) {
                _captureMovieOutput = [AVCaptureMovieFileOutput new];
                _captureMovieOutput.movieFragmentInterval = kCMTimeInvalid;
            }
            if ([_captureSession canAddOutput:_captureMovieOutput]) {
                if (_captureSession.isRunning) {
                    [_captureSession setSessionPreset:[self bestSuitedSessionPresetForResolution:resolution]];
                }
                [_captureSession addOutput:_captureMovieOutput];
            } else {
                NBULogError(@"Can't add output: %@ to session: %@", _captureMovieOutput, _captureSession);
                return NO;
            }
            NBULogVerbose(@"Output: %@ settings: %@", _captureMovieOutput, @"empty");
            break;
        }
        case NBUCameraOutPutModeTypeVideoData: {
            return NO;
            break;
        }
    }
    return YES;
}

#pragma mark 更新输入输出连接

- (void)updateConnection:(NBUCameraOutPutType)outPutType {
    // 更新_captureConnection
    _captureConnection = nil;
    // 修改为根据当前的输出模式来获取
    NSArray *connections;
    switch (outPutType) {
        case NBUCameraOutPutModeTypeImage:
            connections = _captureImageOutput.connections;
            break;
        case NBUCameraOutPutModeTypeVideo:
            connections = _captureMovieOutput.connections;
            break;
        case NBUCameraOutPutModeTypeVideoData:
            connections = _captureVideoDataOutput.connections;
            break;
    }
    for (AVCaptureConnection *connection in connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([port.mediaType isEqualToString:AVMediaTypeVideo]) {
                _captureConnection = connection;
                break;
            }
        }
        if (_captureConnection) {
            NBULogVerbose(@"Video connection: %@", _captureConnection);
            // Handle fron camera video mirroring
            if (_captureDevice.position == AVCaptureDevicePositionFront && _captureConnection.supportsVideoMirroring) {
                _captureConnection.videoMirrored = _keepFrontCameraPicturesMirrored;
            }
            break;
        }
    }
    if (!_captureConnection) {
        NBULogError(@"Couldn't create video connection for output: %@", _captureImageOutput);
    }
}


- (void)toggleCamera:(id)sender {
    NBULogTrace();
    // 正在拍摄直接返回
    if (_captureInProgress || _focusing || [self isRecording] || _transitionAnimating) {
        return;
    }

    _canTake = NO;
    _focusing = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        self.currentCaptureDevice = [_availableCaptureDevices objectAfter:_captureDevice.uniqueID wrap:YES];
    });

    //给摄像头的切换添加翻转动画
    [self doFlipAnimationToggleCamera];
}


#pragma mark 前后镜头切换动画

- (void)doFlipAnimationToggleCamera {
    if (_transitionAnimating || _previewLayer == nil) {
        return;
    }

    _transitionAnimating = YES;

    // 加入遮罩层
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIView *tempView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    tempView.frame = self.bounds;
    [self insertSubview:tempView atIndex:(NSInteger) ([_previewLayer zPosition] + 1)];

    UIView *cameraTransitionView = [self snapshotViewAfterScreenUpdates:YES];
    [self insertSubview:cameraTransitionView atIndex:(NSInteger) ([self.layer zPosition] + 1)];
    [tempView removeFromSuperview];

    _previewLayer.opacity = 0.0;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (_toggleCameraButton) {
            _toggleCameraButton.enabled = NO;
        }
        [UIView transitionWithView:cameraTransitionView
                          duration:0.5
                           options:_captureDevice.position == AVCaptureDevicePositionBack ? UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight
                        animations:nil
                        completion:^(BOOL finished) {
                            _previewLayer.opacity = 1.0;
                            _transitionAnimating = NO;
                            [UIView animateWithDuration:0.2
                                             animations:^() {
                                                 cameraTransitionView.alpha = 0.0;
                                             }
                                             completion:^(BOOL finish) {
                                                 [cameraTransitionView removeFromSuperview];
                                                 if (_toggleCameraButton) {
                                                     _toggleCameraButton.enabled = YES;
                                                 }
                                             }
                            ];
                        }
        ];
    });
}


- (void)updateDeviceConfigurationWithBlock:(void (^)(void))block {
    NSError *error;
    if (![_captureDevice lockForConfiguration:&error]) {
        NBULogError(@"Error: %@", error);
        return;
    }
    block();
    [_captureDevice unlockForConfiguration];

    [self updateUI];
}

#pragma mark - 闪光灯模式

- (AVCaptureFlashMode)currentFlashMode {
    return _captureDevice.flashMode;
}

- (void)setCurrentFlashMode:(AVCaptureFlashMode)currentFlashMode {
    NBULogInfo(@"%@: %@", THIS_METHOD, @(currentFlashMode));

    [self updateDeviceConfigurationWithBlock:^{
        _captureDevice.flashMode = currentFlashMode;
    }];
}

- (void)toggleFlashMode:(id)sender {
    self.currentFlashMode = (AVCaptureFlashMode) [[_availableFlashModes objectAfter:@(self.currentFlashMode)
                                                                               wrap:YES] integerValue];
}

#pragma mark - 对焦模式

- (AVCaptureFocusMode)currentFocusMode {
    return _captureDevice.focusMode;
}

- (void)setCurrentFocusMode:(AVCaptureFocusMode)currentFocusMode {
    NBULogInfo(@"%@: %@", THIS_METHOD, @(currentFocusMode));

    [self updateDeviceConfigurationWithBlock:^{
        _captureDevice.focusMode = currentFocusMode;
    }];
}

- (void)toggleFocusMode:(id)sender {
    self.currentFocusMode = (AVCaptureFocusMode) [[_availableFocusModes objectAfter:@(self.currentFocusMode)
                                                                               wrap:YES] integerValue];
}

#pragma mark - 曝光模式

- (AVCaptureExposureMode)currentExposureMode {
    return _captureDevice.exposureMode;
}

- (void)setCurrentExposureMode:(AVCaptureExposureMode)currentExposureMode {
    NBULogInfo(@"%@: %@", THIS_METHOD, @(currentExposureMode));

    [self updateDeviceConfigurationWithBlock:^{
        _captureDevice.exposureMode = currentExposureMode;
    }];
}

- (void)toggleExposureMode:(id)sender {
    self.currentExposureMode = (AVCaptureExposureMode) [[_availableExposureModes objectAfter:@(self.currentExposureMode)
                                                                                        wrap:YES] integerValue];
}


#pragma mark - 白平衡模式

- (AVCaptureWhiteBalanceMode)currentWhiteBalanceMode {
    return _captureDevice.whiteBalanceMode;
}

- (void)setCurrentWhiteBalanceMode:(AVCaptureWhiteBalanceMode)currentWhiteBalanceMode {
    NBULogInfo(@"%@: %@", THIS_METHOD, @(currentWhiteBalanceMode));

    [self updateDeviceConfigurationWithBlock:^{
        _captureDevice.whiteBalanceMode = currentWhiteBalanceMode;
    }];
}

- (void)toggleWhiteBalanceMode:(id)sender {
    self.currentWhiteBalanceMode = (AVCaptureWhiteBalanceMode) [[_availableWhiteBalanceModes objectAfter:@(self.currentWhiteBalanceMode)
                                                                                                    wrap:YES] integerValue];
}

#pragma mark - 手势 Gestures

- (void)tapped:(UITapGestureRecognizer *)sender {
    if (!_captureDevice || ![sender isKindOfClass:[UITapGestureRecognizer class]]) {
        return;
    }
    // 图片的对焦后拍摄才做这个处理
    if (_shootAfterFocus && _outputType == NBUCameraOutPutModeTypeImage) {
        if (_captureInProgress || _focusing) {// 如果正在对焦,或正在拍摄
            return;
        }
        _focusing = YES;
        _canTake = YES;
    }

    [super tapped:sender];

    // Calculate the point of interest
    CGPoint tapPoint = [sender locationInView:self];// 点击屏幕位置
    _poiView.center = tapPoint;

    CGPoint pointOfInterest;//对焦,白平衡感兴趣的点
    // 这里我加的, 调整对焦位置, 横向为y 纵向为x 原点在右上角(注意是右上角,不是左上角)
    if (self.fixedFocusPoint) {// 如果设置了固定对焦位置
        switch (_captureConnection.videoOrientation) {
            case AVCaptureVideoOrientationPortrait:
                pointOfInterest = CGPointMake(0.725, 0.5);
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
            case AVCaptureVideoOrientationLandscapeRight:
                pointOfInterest = CGPointMake(0.5, 0.5);
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                pointOfInterest = CGPointMake(0.275, 0.5);
                break;
            default:
                pointOfInterest = CGPointMake(0.725, 0.5);
                break;
        }
    } else {// 如果没有设置对焦位置,那么根据点击的位置计算
        pointOfInterest = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    }

    NBULogInfo(@"Adjust point of interest: %@ > %@", NSStringFromCGPoint(tapPoint), NSStringFromCGPoint(pointOfInterest));

    __block BOOL adjustingConfiguration = NO;

    [self updateDeviceConfigurationWithBlock:^{

        // [对焦位置设置]
        if (_captureDevice.isFocusPointOfInterestSupported) {
            NBULogVerbose(@"Focus point of interest...");
            _captureDevice.focusPointOfInterest = pointOfInterest;
            adjustingConfiguration = YES;
        }

        //[曝光位置设置]
        if (_captureDevice.isExposurePointOfInterestSupported) {
            NBULogVerbose(@"Exposure point of interest...");
            _captureDevice.exposurePointOfInterest = pointOfInterest;
            adjustingConfiguration = YES;
        }

        //[平滑自动对焦--只适用于视频拍摄]
        if (_outputType == NBUCameraOutPutModeTypeVideo && _captureDevice.isSmoothAutoFocusEnabled) {
            _captureDevice.smoothAutoFocusEnabled = YES;
            adjustingConfiguration = YES;
        }

        if (self.shootAfterFocus) {//如果是对焦后拍摄
            //[对焦模式设置--自动对焦]
            if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                NBULogVerbose(@"Focusing...");
                _captureDevice.focusMode = AVCaptureFocusModeAutoFocus;
                adjustingConfiguration = YES;
            }

            //[曝光模式设置--自动曝光]
            if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
                NBULogVerbose(@"Adjusting exposure...");
                _captureDevice.exposureMode = AVCaptureExposureModeAutoExpose;
                adjustingConfiguration = YES;
            }

            //[白平衡模式设置--自动白平衡]
            if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                NBULogVerbose(@"Adjusting white balance...");
                _captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeAutoWhiteBalance;
                adjustingConfiguration = YES;
            }
        } else {// [如果不是对焦后拍摄,设置循环对焦]
            // [对焦模式设置--循环对焦]
            if ([_captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                NBULogVerbose(@"Continuous Focusing...");
                _captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                adjustingConfiguration = YES;
            }
            //[曝光模式设置--循环曝光]
            if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                NBULogVerbose(@"Continuous Adjusting exposure...");
                _captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
                adjustingConfiguration = YES;
            }
            //[白平衡模式设置--循环白平衡]
            if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                NBULogVerbose(@"Continuous Adjusting white balance...");
                _captureDevice.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
                adjustingConfiguration = YES;
            }
        }
    }];

    if (adjustingConfiguration) {
        [self flashPoIView];
    } else {
        NBULogVerbose(@"Nothing to adjust for device: %@", _captureDevice);
    }
}

- (void)flashPoIView {
    // We need to stop the animation after a while
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.9 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [_poiView.layer removeAllAnimations];
        _poiView.alpha = 0.0;
    });

    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                         _poiView.alpha = 1.0;
                     }
                     completion:NULL];
}

- (void)doubleTapped:(UITapGestureRecognizer *)sender {
    [super doubleTapped:sender];

    if (![sender isKindOfClass:[UITapGestureRecognizer class]])
        return;
}

// From Apple AVCam demo
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.size;

    if (SYSTEM_VERSION_LESS_THAN(@"6.0") ?
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            _previewLayer.isMirrored :
#pragma clang diagnostic pop
            _captureConnection.isVideoMirrored) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }

    if ([[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize]) {
        // Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [_captureDeviceInput ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;

                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;

                if ([[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        // If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
                            // Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        // If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
                            // Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[_previewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    // Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }

                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }

    return pointOfInterest;
}

#pragma mark - Other methods

// Create a UIImage from sample buffer data
// Based on http://stackoverflow.com/questions/8924299/ios-capturing-image-using-avframework
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
            bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage
                                         scale:1.0
                                   orientation:_sequenceCaptureOrientation];

    // Release the Quartz image
    CGImageRelease(quartzImage);

    return (image);
}

@end


#pragma mark - 点击位置显示, 对焦位置, 自动曝光位置

@implementation PointOfInterestView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(10.0, 10.0, 75.0, 75.0)];
    if (self) {
        self.alpha = 0.0;
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.autoresizingMask = UIViewAutoresizingNone;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIColor *pathColor = [UIColor colorWithRed:1.0
                                         green:1.0
                                          blue:1.0
                                         alpha:1.0];
    UIColor *shadowColor = [UIColor colorWithRed:0.0
                                           green:0.706
                                            blue:1.0
                                           alpha:0.8];
    CGSize shadowOffset = CGSizeZero;
    CGFloat shadowBlurRadius = 6.0;

    // Draw
    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:
                    CGRectMake(shadowBlurRadius,
                            shadowBlurRadius,
                            self.size.width - 2 * shadowBlurRadius,
                            self.size.height - 2 * shadowBlurRadius)
                                                                    cornerRadius:4.0];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context,
            shadowOffset,
            shadowBlurRadius,
            shadowColor.CGColor);
    [pathColor setStroke];
    roundedRectanglePath.lineWidth = 1.0;
    [roundedRectanglePath stroke];
    CGContextRestoreGState(context);
}


@end

