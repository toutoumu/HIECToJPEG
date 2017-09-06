//
//  NBUAsset.h
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

#import "NBUAssetsLibrary.h"
@import Photos;

@class ALAsset, CLLocation;

/// NBUAsset orientations.
typedef NS_ENUM(NSUInteger, NBUAssetOrientation)
{
    NBUAssetOrientationUnknown      = 0,
    NBUAssetOrientationPortrait     = 1,
    NBUAssetOrientationLandscape    = 2,
};

/**
 Wrapper to ease acces to an ALAsset image asset.
 
 - Unlike ALAsset objects, NBUAsset is always valid.
 - Observes ALAssetsLibraryChangedNotification to reload its associated ALAsset if needed.
 - Lazily loads all properties only when needed (except URL).
 
 @note You usually retrieve assets using NBUAssetsLibrary or NBUAssetsGroup methods.
 */
@interface NBUAsset : NSObject

+(CGFloat) scale;
+(CGSize) thumbnailSize;
+(CGSize) fullScreenSize;

/// @name Retrieving Assets

/// 系统资源对象包装 Creates and initializes a NBUAsset associated to an ALAsset.
/// @param ALAsset 系统资源 The associated ALAsset.
/// 初始化 8.x以下系统使用的
+ (NBUAsset *)assetForALAsset:(ALAsset *)ALAsset;

/// 初始化 8.x以上系统使用的
+ (NBUAsset *)assetForPHAsset:(PHAsset *)PHAsset;

/// 初始化 沙箱资源包装 Creates and initializes a NBUAsset associated to a local file.
/// @param fileURL 文件夹路径The Local file's URL.
+ (NBUAsset *)assetForFileURL:(NSURL *)fileURL;

/// 删除照片
- (void) delete:(void(^)(NSError* error,BOOL success))reslutBlock;

/// @name Properties

/// 文件类型 图片|视频 等 The asset type.
@property (nonatomic, readonly)                     NBUAssetType type;

/// 文件url The associated NSURL.
@property (nonatomic, readonly)                     NSURL * URL;

/// 图片旋转 The images orientation, portrait or landscape.
@property (nonatomic, readonly)                     NBUAssetOrientation orientation;

/// 是否可以编辑 Whether the asset is editable or not.
@property(nonatomic, readonly, getter=isEditable)   BOOL editable;

/// 创建日期 The asset creation date.
@property (nonatomic, readonly)                     NSDate * date;

/// 地理位置信息 The asset location.
@property (nonatomic, readonly)                     CLLocation * location;

/// 8.x以下系统使用的,系统资源对象(沙箱不可使用) Associated ALAsset.
@property (nonatomic, readonly)                     ALAsset * ALAsset;

/// 8.x以上系统使用的,系统资源对象(沙箱不可使用)
@property (nonatomic, readonly)                     PHAsset * PHAsset;

/// @name Images

/// 缩略图 A thumbnail-sized image.
@property (nonatomic, readonly)                     UIImage * thumbnailImage;

/// 全屏图片 An image big enough to fill the device's screen.
@property (nonatomic, readonly)                     UIImage * fullScreenImage;

/// 原图 The full resolution image.
@property (nonatomic, readonly)                     UIImage * fullResolutionImage;

@end


/// 沙箱文件使用的,原来是私有类,放在NBUAsset.m文件中现在提取出来公开使用
@interface NBUFileAsset : NBUAsset

+(NSString *)thumbnailDir;
+(NSString *)fullScreenDir;

+ (BOOL) deleteAll: (NSArray *)array;
/// 初始化方法
- (instancetype)initWithFileURL:(NSURL *)fileURL;

/// 缩略图路径
@property (nonatomic, readonly) NSString * thumbnailImagePath;
/// 全屏图片路径
@property (nonatomic, readonly) NSString * fullScreenImagePath;
/// 原图文件名
@property (nonatomic, readonly) NSString * fullResolutionImagePath;

@end

