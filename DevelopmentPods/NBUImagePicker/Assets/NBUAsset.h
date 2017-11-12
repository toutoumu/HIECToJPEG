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

@class CLLocation;

/// NBUAsset orientations.
typedef NS_ENUM(NSUInteger, NBUAssetOrientation) {
    NBUAssetOrientationUnknown = 0,
    NBUAssetOrientationPortrait = 1,
    NBUAssetOrientationLandscape = 2,
};

/**
 Wrapper to ease acces to an ALAsset image asset.
 
 - Unlike ALAsset objects, NBUAsset is always valid.
 - Observes ALAssetsLibraryChangedNotification to reload its associated ALAsset if needed.
 - Lazily loads all properties only when needed (except URL).
 
 @note You usually retrieve assets using NBUAssetsLibrary or NBUAssetsGroup methods.
 */
@interface NBUAsset : NSObject

/**
 * 屏幕缩放
 * @return
 */
+ (CGFloat)scale;

/**
 * 缩略图尺寸(像素值)
 * @return
 */
+ (CGSize)thumbnailSize;

/**
 * 缩略图尺寸(Point值没有*scale)
 * @return
 */
+ (CGSize)thumbnailSizeNoScale;

/**
 * 全屏图片尺寸(像素值)
 * @return
 */
+ (CGSize)fullScreenSize;

/// @name Retrieving Assets

/**
 * 初始化 8.x以上系统使用
 * 系统资源对象包装
 * @param PHAsset
 * @return
 */
+ (NBUAsset *)assetForPHAsset:(PHAsset *)PHAsset;

/**
 * 初始化 沙箱资源包装
 * @param fileURL 文件夹路径 eg: /document/album
 * @return
 */
+ (NBUAsset *)assetForFileURL:(NSURL *)fileURL;

/**
 * 删除照片
 * @param resultBlock 第一个参数:是否发生错误,第二个参数是否完成
 */
- (void)delete:(void (^)(NSError *error, BOOL success))resultBlock;

/// @name Properties

@property(nonatomic) BOOL isSelected;

/** 文件类型 图片|视频 等*/
@property(nonatomic, readonly) NBUAssetType type;

/** 文件路径(沙盒文件使用) eg:/document/abc.jpg */
@property(nonatomic, readonly) NSURL *URL;

/** 图片旋转 The images orientation, portrait or landscape. */
@property(nonatomic, readonly) NBUAssetOrientation orientation;

/** 是否可以编辑 Whether the asset is editable or not. */
@property(nonatomic, readonly, getter=isEditable) BOOL editable;

/** 创建日期 The asset creation date.*/
@property(nonatomic, readonly) NSDate *date;

/** 地理位置信息 The asset location. */
@property(nonatomic, readonly) CLLocation *location;

/** 8.x以上系统使用的,系统资源对象(沙箱不可使用) */
@property(nonatomic, readonly) PHAsset *PHAsset;

/// @name Images

/** 缩略图 A thumbnail-sized image. */
@property(nonatomic, readonly) UIImage *thumbnailImage;

/** 全屏图片 An image big enough to fill the device's screen. */
@property(nonatomic, readonly) UIImage *fullScreenImage;

/** 原图 The full resolution image. */
@property(nonatomic, readonly) UIImage *fullResolutionImage;

@end


/**
 *  沙箱文件使用的,原来是私有类,放在NBUAsset.m文件中现在提取出来公开使用
 */
@interface NBUFileAsset : NBUAsset
/**
 * 初始化方法
 * @param fileURL 文件夹路径 eg:/data/album
 * @return {NBUFileAsset}
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL;

/** 缩略图路径 eg: /data/album/xxx.jpg */
@property(nonatomic, readonly) NSString *thumbnailImagePath;
/** 全屏图片路径 eg: /data/album/xxx.jpg */
@property(nonatomic, readonly) NSString *fullScreenImagePath;
/** 原图文件路径 eg: /data/album/xxx.jpg */
@property(nonatomic, readonly) NSString *fullResolutionImagePath;

/**
 * 缩略图文件夹名称 eg:picture
 * @return 缩略图文件夹名称
 */
+ (NSString *)thumbnailDir;

/**
 * 全屏图片文件夹名称 eg:picture
 * @return 全屏图片文件夹名称
 */
+ (NSString *)fullScreenDir;

@end

