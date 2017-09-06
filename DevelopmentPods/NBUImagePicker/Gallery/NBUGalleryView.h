//
//  NBUGalleryView.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2013/04/17.
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

@class NBUGalleryViewController;

/**
 *   A view to be used to display each element of the [NBUGalleryViewController objectArray].

 Can be customized from a Nib file.
 相册浏览图片 用于显示相册的单张浏览时候的图片
 */
@interface NBUGalleryView : UIView

/// @name Properties

/// The view's controller should be a NBUGalleryViewController instance.
@property (nonatomic, readonly)         NBUGalleryViewController * viewController;

/// 是否显示加载中 Whether the view should show its activityView.
@property (nonatomic, getter=isLoading) BOOL loading;

/// @name Methods

/// 重置图片的缩放大小到初始化大小 Reset the view's zoom to the initial state.
- (void)resetZoom;

/// @name Outlets

/// 单张显示的图片 A UIImageView to display the image.
@property (weak, nonatomic) IBOutlet    UIImageView * imageView;

/// 加载进度条 An optional view to be shown/hidden according to the loading value.
@property (weak, nonatomic) IBOutlet    UIView * activityView;

@end

