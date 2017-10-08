//
//  NBUAssetsGroup.h
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
// 相册数据包装模型
#import "NBUAssetsLibrary.h"

/**
 Wrapper to ease acces to an ALAssetsGroup & PHAssetCollection assets group.
 
 - Unlike ALAssetsGroup objects, NBUAssetsGroup is always valid.
 - Observes ALAssetsLibraryChangedNotification to reload its associated
 ALAssetsGroup if needed.
 - Lazily loads posterImage and assets' count only when needed.
 - Leverages iOS4 compatibility by creating a NSURL:
 `assets-library://group/?id=<ALAssetsGroupPropertyPersistentID>`.
 
 @note You usually retrieve assets groups using NBUAssetTypesLibrary methods.
 */
@interface NBUAssetsGroup : NSObject

/// @name Initializers

/**
 * 批量删除
 * @param array
 * @param resultBlock 第一个参数错误信息,第二个参数是否执行完成,第三个参数当前删除的数据
 */
- (void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL, NBUAsset *))resultBlock;

/**
 *  8.0+系统使用的相册对象初始化方法
 *  @param PHAssetCollection PHAssetCollection相册对象
 *  @return NBUAssetsGroup 子类
 */
+ (NBUAssetsGroup *)groupForPHAssetsGroup:(PHAssetCollection *)PHAssetCollection;

/**
 * 沙箱相册初始化 Creates and initializes a NBUAssetsGroup associated to a local directory.
 * @discussion Use [NBUAssetsLibrary registerDirectoryGroupforURL:name:] to let the assets library automatically create and display the assets group for you.
 * @param directoryURL 沙箱目录 The target directory's URL.
 * @param name 可选的显示名称,如果为空则取目录名称 The optional name to be used for the NBUAssetsGroup.
 * @return NBUAssetsGroup 相册实例
 */
+ (NBUAssetsGroup *)groupForDirectoryURL:(NSURL *)directoryURL name:(NSString *)name;

/// @name Properties

/** 相册类型 The NBUAssetsGroupType of the group. */
@property(nonatomic, readonly) NBUAssetsGroupType type;

/** 相册名称 The group's name. */
@property(nonatomic, readonly) NSString *name;

/** 是否可以编辑 Whether the group is editable or not. */
@property(nonatomic, readonly, getter=isEditable) BOOL editable;

/** 封面照片 A thumbnail-sized poster image. */
@property(nonatomic, readonly) UIImage *posterImage;

/** 8.x以上系统的相册对象 相当于8.0-中的ALAssetsGroup */
@property(strong, nonatomic, readonly) PHAssetCollection *PHAssetCollection;

/// @name 资源数量 Accessing Assets

/** 资源数 The total number of assets. */
@property(nonatomic, readonly) NSUInteger assetsCount;

/** 图片数 The total number of image assets. */
@property(nonatomic, readonly) NSUInteger imageAssetsCount;

/** 视频数 The total number of video assets. */
@property(nonatomic, readonly) NSUInteger videoAssetsCount;

/// @name Retrieving Assets

/**
 * 加载相册资源 Returns the assets matching an ALAssetsFilter.
 * @param types 资源类型(图片|视频|图片&视频) The desired type mask of assets to retrieve.
 * @param indexSet 加载哪些 The index of the desired assets. Pass `nil` to get all the assets.
 * @param reverseOrder 是否反序 Set to `YES` to get newer to older assets.
 * @param loadSize 一次加载多少,为0表示全部加载 If different to zero the resultBlock will be called after loading another loadSize number of assets.
 * @param resultBlock 回调方法 The block to be called asynchronously with the results.
 */
- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock;

/**
 * 停止加载 Ask the group to abort retrieving assets, and thus stop calling the resultBlock.
 */
- (void)stopLoadingAssets;

@end


/**
 * 沙盒相册,原来是放在NBUAssetsGroup.m文件中作为私有类使用,现在提取出来作为公有类使用
 */
@interface NBUDirectoryAssetsGroup : NBUAssetsGroup

/**
 *  沙盒相册初始化
 *
 *  @param directoryURL 沙盒相册的路径 eg:/document/album
 *  @param name         相册名称 eg: album
 *
 *  @return NBUAssetsGroup 实例
 */
- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL name:(NSString *)name;

@end

