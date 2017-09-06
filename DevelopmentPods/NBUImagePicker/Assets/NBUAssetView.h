//
//  NBUAssetView.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/08/01.
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
// 缩略图基类
#import "ObjectView.h"

@class NBUAsset;

/// NBUAsset image sizes.
typedef NS_ENUM(NSUInteger, NBUAssetImageSize)
{
    NBUAssetImageSizeAuto           = 0,
    NBUAssetImageSizeThumbnail      = 1,
    NBUAssetImageSizeFullScreen     = 2,
    NBUAssetImageSizeFullResolution = 3,
};

/**
 缩略图基类 Customizable ObjectView used to present a NBUAsset object.
 
 - Automatically chooses the best-suited NBUAssetImageSize to display for the asset.
 */
@interface NBUAssetView : ObjectView

/// 图片数据 The associated NBUAsset asset
@property (strong, nonatomic, setter=setObject:,
                              getter=object)        NBUAsset * asset;

/// @name Properties

/// The target NBUAssetImageSize to be loaded.
/// @discussion Default NBUAssetImageSizeAuto which will choose the most appropiate size.
@property (nonatomic)                               NBUAssetImageSize targetImageSize;

/// The currently used NBUAssetImageSize.
@property (nonatomic)                               NBUAssetImageSize currentImageSize;

/// @name Outlets

/// 缩略图 An UIImageView used to show the [NBUAsset thumbnailImage].
@property (weak, nonatomic) IBOutlet                UIImageView * imageView;

@end

