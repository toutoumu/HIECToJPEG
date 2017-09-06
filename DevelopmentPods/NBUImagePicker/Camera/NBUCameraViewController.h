//
//  NBUCameraViewController.h
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
// 相机控制器
#import <NBUKit/NBUViewController.h>
#import "NBUCameraView.h"

/**
 An extensible UIViewController for a NBUCameraView.
 
 - Forwards properties to the underlying cameraView.
 */
@interface NBUCameraViewController : NBUViewController
#pragma mark - Properties
/// @name NBUCameraView Properties

/// Whether a camera device is available.
/// 相机是否可用 @note There is a mock camera mode for the iPhone simulator.
+ (BOOL)isCameraAvailable;

/// 照片尺寸 Property passed to cameraView's [NBUCameraView targetResolution].
@property (nonatomic)                   CGSize targetResolution;

/// 拍摄完成之后(未保存图片)的回调,非UI线程 Property passed to cameraView's [NBUCameraView captureResultBlock].
@property (nonatomic, copy)             NBUCapturePictureResultBlock captureResultBlock;

/// 是否保存照片到相册 Whether to save the pictures to the the library. Default `NO`.
@property (nonatomic)                   BOOL savePicturesToLibrary;

/// If set along savePicturesToLibrary the assets will be added to a given album.
/// 照片保存目录 @note A new album may be created if necessary.
@property (nonatomic, strong)           NSString * targetLibraryAlbumName;

/// Whether to use single picture mode. Default `NO`.
/// 是否为单张拍摄模式 默认为no @discussion In this mode [NBUCameraView lastPictureImageView] will be removed.
@property (nonatomic)                   BOOL singlePictureMode;

/// 是否允许音量调节按钮点击拍摄照片 Whether Volume Up and Volume Down buttons should be used to take pictures. Default `YES` for iOS5+.
@property (nonatomic)                   BOOL takesPicturesWithVolumeButtons;

#pragma mark - Outlets
/// @name Outlets

/// 相机视图 The camera underlying view.
@property (weak, nonatomic) IBOutlet    NBUCameraView * cameraView;

/// 当相机不可访问时候显示的视图 An optional view to be shown (`hidden = NO`) when the user has denied access to the camera.
@property (strong, nonatomic) IBOutlet  UIView * accessDeniedView;

/// 显示当前闪光灯模式的 label A label that displays the [NBUCameraView currentFlashMode].
@property (weak, nonatomic) IBOutlet    UILabel * flashLabel;

/// 显示当前曝光模式的 label A label that displays the [NBUCameraView currentFlashMode].
@property (weak, nonatomic) IBOutlet    UILabel * exposureLabel;

/// 显示当前对焦模式的 label A label that displays the [NBUCameraView currentFlashMode].
@property (weak, nonatomic) IBOutlet    UILabel * focusLabel;

/// 显示当前白平衡模式的 label A label that displays the [NBUCameraView currentFlashMode].
@property (weak, nonatomic) IBOutlet    UILabel * whiteBalanceLabel;

@end

