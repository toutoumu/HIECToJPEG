//
//  NBUCameraView.h
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

#import "ActiveView.h"
#import <AVFoundation/AVCaptureDevice.h>

@protocol UIButton;

/// block宏定义 NBUCameraView blocks.
typedef void (^NBUCapturePictureResultBlock)(UIImage * image,
                                             NSError * error);
typedef void (^NBUSavePictureResultBlock)(UIImage * image,
                                          NSDictionary * metadata,
                                          NSURL * url,
                                          NSError * error);
typedef void (^NBUCaptureMovieResultBlock)(NSURL * movieURL,
                                           NSError * error);
typedef void (^NBUButtonConfigurationBlock)(id<UIButton> button,
                                            NSInteger mode);

/// 当前相机的输出模式, 视频,图片,默认为图片.
typedef NS_ENUM(NSInteger, NBUCameraOutPutType)
{
    NBUCameraOutPutModeTypeImage       = 0,
    NBUCameraOutPutModeTypeVideo       = 1 << 0,
    //NBUCameraOutPutModeTypeVideoDat    = 1 << 1,
};

/**
 Fully customizable camera view based on AVFoundation.
 
 - Set target resolution.
 - Customizable controls/buttons and layout.
 - Supports flash, focus, exposure and white balance settings.
 - Can automatically save to device's Camera Roll/custom albums.
 - Can be used with any UIViewController, so it can be embedded in a UITabView, pushed to a UINavigationController, presented modally, etc.
 - Works with simulator.
 - Proper orientation support both in autorotation-locked devices and simulator.
 */
@interface NBUCameraView : ActiveView
#pragma mark 是否是否显示预览图层,默认YES
@property (nonatomic)                   BOOL showPreviewLayer;
#pragma mark 是否固定对焦点的位置,默认为NO
@property (nonatomic)                   BOOL fixedFocusPoint;
#pragma mark 是否先对焦后拍摄,默认为NO,如果为NO会设置 [循环自动对焦],如果为YES 不会设置为循环自动对焦
@property (nonatomic)                   BOOL shootAfterFocus;
#pragma mark 是否正在对焦
@property (nonatomic)                   BOOL focusing;
#pragma mark 当前相机是拍照,还是视频
@property (nonatomic, readonly)         NBUCameraOutPutType currentOutPutType;

#pragma mark 视频,图片拍摄切换
-(void)toggleCameraType:(CGSize) targetResolution targetFrame:(CGRect) targetFrame resultBlock:(void(^)(NBUCameraOutPutType ,BOOL))callback;

/// @name Configurable Properties

/// The minimum desired resolution.
/// @discussion If not set full camera resolution will be used but to improve performance
/// you could set a lower resolution.
/// 照片分辨率 @note The captured image may not exactly match the targetResolution.
@property (nonatomic)                   CGSize targetResolution;

/// Programatically force the view to rotate.
/// @param orientation The desired interface orientation.
- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation;
#pragma mark - Picture Properties
/// 图片拍摄相关的属性 @name Picture Properties

/// 拍摄完成之后(未保存)的回调,非UI线程 和 Sequence 共用一个回调 block The block to be called immediately after capturing the picture.
@property (nonatomic, copy)             NBUCapturePictureResultBlock captureResultBlock;

/// 是否保存照片到相册 Whether to save the pictures to the the library. Default `NO`.
@property (nonatomic)                   BOOL savePicturesToLibrary;

/// If set along savePicturesToLibrary the assets will be added to a given album.
/// 照片保存的目录,如果不存在则创建 @note A new album may be created if necessary.
@property (nonatomic, strong)           NSString * targetLibraryAlbumName;

/// The optional block to be called if savePicturesToLibrary is enabled.
/// 照片保存之后的回调 @note This block has some delay over captureResultBlock.
@property (nonatomic, copy)             NBUSavePictureResultBlock saveResultBlock;

/// Whether the view should compensate device orientation changes. Default `NO`.
/// 是否允许旋转?? 如果设置为 YES , 那么将手机横向放置的时候 ,预览的图像将旋转90度 ,也就是你在手机上看到的将是旋转了90度的图像
/// @note Set to `YES` when inside view controllers that support rotation.
@property (nonatomic)                   BOOL shouldAutoRotateView;

/// Whether front camera's pictures should be captured mirrored.
/// Default `NO` meaning that front camera pictures are not mirrored.
/// 前置摄像头预览是否为镜像 @note Front camera's preview is always mirrored.
@property(nonatomic)                    BOOL keepFrontCameraPicturesMirrored;

/// 拍照完成后图片是否有放入相册的动画效果 Whether the lastPictureImageView should be animated. Default `YES`.
@property(nonatomic)                    BOOL animateLastPictureImageView;

/// 图片序列相关的属性 @name Picture Sequence Properties

/// 照片拍摄的间隔 The interval at which images should be captured.
@property (nonatomic)                   NSTimeInterval sequenceCaptureInterval;

/// Whether the camera is currently capturing a sequence of images.
@property (nonatomic, readonly,
           getter=isCapturingSequence)  BOOL capturingSequence;

/// 视频拍摄相关的属性 @name Movie Properties

/// The local folder where recorded movies should be recorded.
/// 视频保存目录默认为 Documents文件夹 @discussion If not specified movies will be saved to the application's Documents folder.
@property (nonatomic, strong)           NSURL * targetMovieFolder;

/// 视频拍摄完成之后的回调 The block to be called after capturing a movie.
@property (nonatomic, copy)             NBUCaptureMovieResultBlock captureMovieResultBlock;

/// 是否正在拍摄视频 Whether recording is in progress.
@property (nonatomic, readonly,
           getter=isRecording)          BOOL recording;

/// 权限相关 @name Access Permissions

/// 用户是否允许该应用使用相机 Whether the user has actively denied access to the camera.
@property (nonatomic, readonly)         BOOL userDeniedAccess;

/// 家长控制是否允许使用相机 Whether parental controls have denied access to the camera.
@property (nonatomic, readonly)         BOOL restrictedAccess;

/// @name Capture Devices and Modes

/// The available capture devices' uniqueID's (ex. Front, Back camera).
/// 可用的相机(前置,后置) @see [AVCaptureDevice uniqueID].
@property (strong, nonatomic, readonly) NSArray * availableCaptureDevices;

/// The current capture device's uniqueID.
/// @discussion Changing the current device refreshes the availableFlashModes, availableFocusModes,
/// 当前使用的相机(前置|后置) availableExposureModes and availableWhiteBalanceModes.
@property (strong, nonatomic)           NSString * currentCaptureDevice;

/// 可用的分辨率模式 The current device's available capture presets and resolutions.
@property (nonatomic, strong)           NSDictionary * availableResolutions;

/// 可用的闪光灯模式 The current device's available AVCaptureFlashMode modes.
@property (strong, nonatomic, readonly) NSArray * availableFlashModes;

/// The current capture device's AVCaptureFlashMode.
/// 当前闪光灯模式 @see availableFlashModes.
@property (nonatomic)                   AVCaptureFlashMode currentFlashMode;

/// 当前可用的对焦模式 The current device's available AVCaptureFocusMode modes.
@property (strong, nonatomic, readonly) NSArray * availableFocusModes;

/// The current capture device's AVCaptureFocusMode.
/// 当前对焦模式 @see availableFocusModes.
@property (nonatomic)                   AVCaptureFocusMode currentFocusMode;

/// 当前可用的曝光模式 The current device's available AVCaptureExposureMode modes.
@property (strong, nonatomic, readonly) NSArray * availableExposureModes;

/// The current capture device's AVCaptureExposureMode.
/// 当前曝光模式 @see availableExposureModes.
@property (nonatomic)                   AVCaptureExposureMode currentExposureMode;

/// 当前可用的白平衡模式 The current device's available AVCaptureWhiteBalanceMode modes.
@property (strong, nonatomic, readonly) NSArray * availableWhiteBalanceModes;

/// The current capture device's AVCaptureWhiteBalanceMode.
/// 当前白平衡模式@see availableWhiteBalanceModes.
@property (nonatomic)                   AVCaptureWhiteBalanceMode currentWhiteBalanceMode;

/// @name Customizing the UI Controls

/// 是否隐藏禁用的按钮 Whether to hide disabled controls. Default `NO`.
@property (nonatomic)                   BOOL showDisabledControls;

/// 前后摄像头切换之后的回调 The block to be used to configure the toggleCameraButton.
@property (nonatomic, copy)             void(^toggleCameraButtonConfigurationBlock)(id<UIButton> button, AVCaptureDevicePosition position);
/// 闪光灯模式切换之后的回调The block to be used to configure the flashButton.
@property (nonatomic, copy)             void(^flashButtonConfigurationBlock)(id<UIButton> button, AVCaptureFlashMode mode);
/// 对焦模式切换之后的回调The block to be used to configure the focusButton.
@property (nonatomic, copy)             void(^focusButtonConfigurationBlock)(id<UIButton> button, AVCaptureFocusMode mode);
/// 曝光模式切换之后的回调The block to be used to configure the exposureButton.
@property (nonatomic, copy)             void(^exposureButtonConfigurationBlock)(id<UIButton> button, AVCaptureExposureMode mode);
/// 白平衡模式切换之后的回调The block to be used to configure the whiteBalanceButton.
@property (nonatomic, copy)             void(^whiteBalanceButtonConfigurationBlock)(id<UIButton> button, AVCaptureWhiteBalanceMode mode);

#pragma mark - Actions
/// @name Actions

/// Take a picture and execure the resultBlock.
/// 拍照事件 @param sender The sender object.
- (IBAction)takePicture:(id)sender;

/// Start/stop a picture capture sequence.
/// 开始|结束sequence采集图片事件 @param sender The sender object.
- (IBAction)startStopPictureSequence:(id)sender;

/// Start or stop video recording.
/// 开始|结束拍摄事件 @param sender The sender object.
- (IBAction)startStopRecording:(id)sender;

/// Switch between front and back cameras (if available).
/// @discussion Configures toggleCameraButton using toggleCameraButtonConfigurationBlock when available.
/// @param sender The sender object.
/// 前后摄像头切换事件 @see availableCaptureDevices.
- (IBAction)toggleCamera:(id)sender;

/// Change the flash mode (if available).
/// @discussion Configures flashButton using flashButtonConfigurationBlock when available.
/// 闪光灯切换模式 @param sender The sender object.
- (IBAction)toggleFlashMode:(id)sender;

/// Change the focus mode (if available).
/// @discussion Configures focusButton using focusButtonConfigurationBlock when available.
/// 对焦模式切换事件 @param sender The sender object.
- (IBAction)toggleFocusMode:(id)sender;

/// Change the exposure mode (if available).
/// @discussion Configures exposureButton using exposureButtonConfigurationBlock when available.
/// 曝光模式切换事件 @param sender The sender object.
- (IBAction)toggleExposureMode:(id)sender;

/// Change the white balance mode (if available).
/// @discussion Configures whiteBalanceButton using whiteBalanceButtonConfigurationBlock when available.
/// 白平衡切换事件 @param sender The sender object.
- (IBAction)toggleWhiteBalanceMode:(id)sender;

/// @name Creating UI Configuration Blocks

/// Create a NBUButtonConfigurationBlock that sets the title of a
/// button using `[NSString stringWithFormat:format, mode]`.
/// @param format A string format for a NSInteger. Ex. `@"Flash: %d"`.
- (NBUButtonConfigurationBlock)buttonConfigurationBlockWithTitleFormat:(NSString *)format;

/// Create a NBUButtonConfigurationBlock that sets the title from an array of titles
/// using the mode as index.
/// 根据当前的闪光灯,曝光模式等的值匹配titles数组中的值,显示到View上面 @param titles The possible titles. One for each mode.
/// 使用方法 cameraView.flashButtonConfigurationBlock = [cameraView buttonConfigurationBlockWithTitleFrom: @[@"关", @"开", @"自动"]];
/// cameraView.focusButtonConfigurationBlock = [cameraView buttonConfigurationBlockWithTitleFrom: @[@"锁定对焦", @"自动对焦", @"连续对焦"]];
- (NBUButtonConfigurationBlock)buttonConfigurationBlockWithTitleFrom:(NSArray *)titles;

#pragma mark - Outlets
/// @name UI Outlets

/// 拍摄按钮 The button to takePicture:.
@property (weak, nonatomic) IBOutlet id<UIButton> shootButton;

/// 前置,后置摄像头切换按钮 The optional button to toggleCamera:.
@property (weak, nonatomic) IBOutlet id<UIButton> toggleCameraButton;

/// 闪光灯切换按钮 The optional button to toggleFlashMode:.
@property (weak, nonatomic) IBOutlet id<UIButton> flashButton;

/// 对焦模式切换按钮 The optional button to toggleFocusMode:.
@property (weak, nonatomic) IBOutlet id<UIButton> focusButton;

/// 曝光模式切换按钮 The optional button to toggleExposureMode:.
@property (weak, nonatomic) IBOutlet id<UIButton> exposureButton;

/// 白平衡模式切换按钮 The optional button to toggleWhiteBalanceMode:.
@property (weak, nonatomic) IBOutlet id<UIButton> whiteBalanceButton;

/// The optional UIImageView to be used to display the last taken picture.
/// 拍摄的最后一张照片显示控件 @note Check the PickerDemo project for other ways to customize displaying the last taken pictures.
@property (weak, nonatomic) IBOutlet UIImageView * lastPictureImageView;

#pragma mark 相机切换遮罩层容器,必须保证这个容器包含CameraView
@property (weak, nonatomic) IBOutlet UIView* maskViewContainer;

@end
