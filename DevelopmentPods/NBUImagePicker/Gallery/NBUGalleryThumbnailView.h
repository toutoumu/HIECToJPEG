//
//  NBUGalleryThumbnailView.h
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

#import "ActiveView.h"

@class NBUGalleryViewController;

/**
 NBUGalleryViewController's thumbnail view.
 
 Can be customized from a Nib file.
 缩略图 显示用的视图,可以由自己配置
 */
@interface NBUGalleryThumbnailView : ActiveView

/// @name Properties

/// The view's controller should be a NBUGalleryViewController instance.
/// @discussion Taps on the view will trigger [NBUGalleryViewController thumbnailWasTapped:]
/// on its controller.
@property (weak, nonatomic)             NBUGalleryViewController * viewController;

/// @name Outlets

/// 缩略图图片视图 A UIImageView to display the thumbnail.
@property (weak, nonatomic) IBOutlet    UIImageView * imageView;

@end

