//
//  NBUEditImageViewController.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/11/30.
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

#import "NBUObjectViewController.h"

@class NBUMediaInfo, NBUPresetFilterView, NBUCropView;

/// 剪切结束回调 NBUCameraView blocks.
typedef void (^NBUEditImageResultBlock)(UIImage * image);
/// 剪切开始
typedef void (^NBUEditImageStartBlock)();
/// 剪切结束
typedef void (^NBUEditImageFinishBlock)();

/**
 A view controller to handle a NBUPresetFilterView and/or a NBUCropView.
 */
@interface NBUEditImageViewController : NBUObjectViewController

/// @name Hanlding Images

/// 需要裁剪的图片 The source image.
@property (strong, nonatomic, setter=setObject:,
                              getter=object)        UIImage * image;

/// 编辑后的图片 The edited image.
/// @note Every time you call this method the image is processed again.
- (UIImage *)editedImage;

/// The optional block to be called when the apply: action is triggered.
@property (nonatomic, copy)                         NBUEditImageResultBlock resultBlock;
/// 剪切开始
@property (nonatomic, copy)                         NBUEditImageStartBlock startBlock;
/// 剪切结束
@property (nonatomic, copy)                         NBUEditImageFinishBlock finishBlock;

/// @name Handling Media Info Objects

/// The source NBUMediaInfo object.
@property (strong, nonatomic)                       NBUMediaInfo * mediaInfo;

/// Update and return the mediaInfo with edition information.
- (NBUMediaInfo *)editedMediaInfo;

/// @name Configuring Cropping

/// An optional target size. If set edited images will be downsized to fit this size.
/// Default `CGSizeZero` which means no resizing of the cropped image.
@property (nonatomic)                               CGSize cropTargetSize;

/// The size relative to the UIScreen points to be used to crop the image.
/// @see NBUCropView.
@property (nonatomic)                               CGSize cropGuideSize;

///最大缩放级别 Maximum scale factor to be allowed to use.
/// @see NBUCropView.
@property (nonatomic)                               CGFloat maximumScaleFactor;

/// @name Configuring Filters

/// The current set of filters.
/// @see NBUPresetFilterView.
@property (strong, nonatomic)                       NSArray * filters;

/// The desired working size for the preview.
/// @see NBUPresetFilterView.
@property (nonatomic)                               CGSize workingSize;

/// @name Outlets

#if __has_include("NBUFilters.h")
/// The optional NBUPresetFilterView.
@property (weak, nonatomic) IBOutlet                NBUPresetFilterView * filterView;
#endif

/// The optional NBUCropView.
@property (weak, nonatomic) IBOutlet                NBUCropView * cropView;

/// @name Methods

/// Reset the crop and/or filter view.
/// @param sender The sender object.
- (IBAction)reset:(id)sender;

/// Apply the editions to the image and call the resul  tBlock if set.
/// @param sender The sender object.
- (IBAction)apply:(id)sender;

@end

