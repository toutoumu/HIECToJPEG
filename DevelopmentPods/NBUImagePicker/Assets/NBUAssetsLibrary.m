//
//  NBUAssetsLibrary.m
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
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "NBUImagePickerPrivate.h"
#import "../../../../../../../libs/XCodeSDK/ios9.3/iPhoneOS9.3.sdk/System/Library/Frameworks/AssetsLibrary.framework/Headers/AssetsLibrary.h"
@import Photos;


NSString *const NBUAssetsErrorDomain = @"NBUAssetsErrorDomain";

static NBUAssetsLibrary *_sharedLibrary = nil;

@implementation NBUAssetsLibrary {
    NSMutableDictionary *_directories;// 沙盒相册集合
}

#pragma mark - Initialization

+ (NBUAssetsLibrary *)sharedLibrary {
    if (!_sharedLibrary) {
        [NBUAssetsLibrary new];
    }
    return _sharedLibrary;
}

+ (void)setSharedLibrary:(NBUAssetsLibrary *)library {
    _sharedLibrary = library;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _PHCachingImageManager = [[PHCachingImageManager alloc] init];
        _directories = [NSMutableDictionary dictionary];

        // Set the first object as the singleton
        if (!_sharedLibrary) {
            _sharedLibrary = self;
        }

        // Observe library changes
        /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(libraryChanged:)
                                                     name:ALAssetsLibraryChangedNotification
                                                   object:nil];*/
    }
    return self;
}

- (void)dealloc {
    // Stop observing
    /*[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ALAssetsLibraryChangedNotification
                                                  object:nil];*/
}

/// 导出相片到系统相册 ---- 区分系统版本
+ (void)addAll:(NSArray *)array toAlbum:(NSString *)albumName withBlock:(void (^)(NSError *, BOOL, int))resultBlock {

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 尝试获取相册
        [[NBUAssetsLibrary sharedLibrary] groupWithName:albumName resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            PHAssetCollection *collection = nil;//相册
            if (group != nil) {
                collection = [group PHAssetCollection];
            } else {//相册不存在, 创建相册
                __block NSString *collectionId = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *assetCollectionChangeRequest = nil;
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
                    collectionId = [assetCollectionChangeRequest placeholderForCreatedAssetCollection].localIdentifier;
                }                                                    error:&error];
                if (error) {
                    if (resultBlock) {//操作完成
                        resultBlock(error, YES, 0);
                    }
                    return;
                }
                collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
                if (collection == nil) {
                    if (resultBlock) {//操作完成
                        resultBlock(error, YES, 0);
                    }
                    return;
                }
            }

            int i = 0;
            for (NBUFileAsset *image in array) {
                i++;
                if (resultBlock) {//操作过程中,报告进度
                    resultBlock(nil, false, i);
                }
                // 由于使用一次请求添加多张照片会导致内存溢出,因此这里采取的是 每次一张图片都单独做一个请求来保存
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                    if (image.type == NBUAssetTypeImage) {//图片
                        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[image.fullResolutionImage imageWithOrientationUp]];
                        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
                    } else {//视频
                        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:image.URL];
                        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
                    }
                }                                                    error:&error];
                if (error != nil) {//执行出错
                    resultBlock(error, YES, i);
                    NBULogInfo(@"Error creating asset: %@", error);
                    return;
                }
            }
            if (resultBlock) {//操作完成
                resultBlock(error, YES, array.count);
            }
        }];
        return;
    }
}


#pragma mark 注册沙盒中的相册

- (void)registerDirectoryGroupForURL:(NSURL *)directoryURL
                                name:(NSString *)name {
    _directories[directoryURL] = name ? name : [NSNull null];
}

- (void)libraryChanged:(NSNotification *)notification {
    NBULogVerbose(@"Library changed: %@ userInfo: %@", notification, notification.userInfo);
}

#pragma mark - Access permissions

- (BOOL)userDeniedAccess {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        // Check with ALAssetsLibrary
        //return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied;
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied;
    } else {
        // Check with ALAssetsLibrary
        return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied;
    }
}

- (BOOL)restrictedAccess {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        // Check with ALAssetsLibrary
        //return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted;
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted;
    } else {
        // Check with ALAssetsLibrary
        return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted;
    }
}

#pragma mark - 相册相关操作 Retrieving asset groups
#pragma mark 加载所有的沙盒中的目录

- (void)directoryGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock {
    // 异步加载沙盒中的目录
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *groups = [NSMutableArray array];
        id name;
        for (NSURL *directoryURL in _directories) {
            name = _directories[directoryURL];
            [groups addObject:[NBUAssetsGroup groupForDirectoryURL:directoryURL
                                                              name:name == [NSNull null] ? nil : name]];
        }
        resultBlock(groups, nil);
    });
}

#pragma mark 加载沙盒&系统相册

- (void)allGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock {
    NSMutableArray *groups = [NSMutableArray array];

    // 加载所有的沙盒中的目录 First all directory groups
    [self directoryGroupsWithResultBlock:^(NSArray *directoryGroups,
            NSError *directoryError) {
        if (directoryGroups) {
            [groups addObjectsFromArray:directoryGroups];
        }

        // 加载系统相册 Then all AL albums
        [self albumGroupsWithResultBlock:^(NSArray *albumGroups,
                NSError *albumError) {
            if (albumGroups) {
                [groups addObjectsFromArray:albumGroups];
            }

            resultBlock(groups, albumError);
        }];
    }];
}

#pragma mark 加载所有系统相册(胶卷&照片流&图片库)----方法内部区分系统版本

- (void)albumGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock {
    NSMutableArray *groups = [NSMutableArray array];
    // 8.0以上系统使用
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 列出所有相册智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
            [groups addObject:[NBUAssetsGroup groupForPHAssetsGroup:obj]];
            NBULogInfo(@"相册名称:%@", obj.localizedTitle);
        }];

        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [topLevelUserCollections enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
            NBULogInfo(@"相册名称:%@", obj.localizedTitle);
            [groups addObject:[NBUAssetsGroup groupForPHAssetsGroup:obj]];
        }];
        resultBlock(groups, nil);
    }
}

#pragma mark 创建相册, 区分系统版本

- (void)createAlbumGroupWithName:(NSString *)name
                     resultBlock:(NBUAssetsGroupResultBlock)resultBlock {
    // 8.0以上系统查找相册
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 尝试查找相册
        [[NBUAssetsLibrary sharedLibrary] groupWithName:name resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            if (error) {// 查找出错
                if (resultBlock) {
                    resultBlock(nil, error);
                }
                return;
            }
            if (group != nil) {// 查找成功
                if (resultBlock) {
                    resultBlock(group, error);
                }
                return;
            }
            // 相册不存在, 创建相册
            __block NSString *collectionId = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] /*performChanges*/ performChangesAndWait:^{
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = nil;
                assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
                collectionId = [assetCollectionChangeRequest placeholderForCreatedAssetCollection].localIdentifier;
            }                                                                       error:&error
                    /*completionHandler:^(BOOL success, NSError *error) {
                     if (groupBlock == nil) {
                     PHAssetCollection *collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
                     resultBlock([NBUAssetsGroup groupForPHAssetsGroup:collection],error);
                     }else{
                     resultBlock(groupBlock,error);
                     }
                     }*/
            ];
            if (error != nil) {//创建出错
                if (resultBlock) {
                    resultBlock(nil, error);
                }
                return;
            }
            if (collectionId != nil) {// 获取创建的相册
                PHAssetCollection *collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
                if (resultBlock) {
                    resultBlock([NBUAssetsGroup groupForPHAssetsGroup:collection], error);

                }
            } else {
                if (resultBlock) {
                    resultBlock(nil, error);
                }
            }
        }];
        return;
    }
}

#pragma mark 根据名称查找相册.区分系统版本

- (void)groupWithName:(NSString *)name
          resultBlock:(NBUAssetsGroupResultBlock)resultBlock {
    // Enumeration block
    __block BOOL found = NO;
    // 8.0以上系统查找相册
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [topLevelUserCollections enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
            NBULogInfo(@"相册名称:%@", obj.localizedTitle);
            if ([obj.localizedTitle isEqualToString:name]) {
                *stop = YES;
                resultBlock([NBUAssetsGroup groupForPHAssetsGroup:obj], nil);
                found = YES;
            }
        }];

        if (found) {
            return;
        }

        // 列出所有相册智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
            NBULogInfo(@"相册名称:%@", obj.localizedTitle);
            if ([obj.localizedTitle isEqualToString:name]) {
                *stop = YES;
                resultBlock([NBUAssetsGroup groupForPHAssetsGroup:obj], nil);
                found = YES;
            }
        }];

        if (!found) {
            resultBlock(nil, nil);
        }
        return;
    }
}


#pragma mark - 图片操作 Retrieve assets
#pragma mark 根据传入的类型获取文件 图片, 视频, 或全部类型

- (void)allAssetsWithTypes:(NBUAssetType)types
               resultBlock:(NBUAssetsResultBlock)resultBlock; {
    NBULogVerbose(@"All assets with type %@...", @(types));

    NSMutableArray *assets = [NSMutableArray array];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {//代码未测试
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        switch (types) {//类型
            case NBUAssetTypeImage: {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
                break;
            }
            case NBUAssetTypeVideo: {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
                break;
            }
            default: {
                break;
            }
        }

        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
        if ([fetchResult count] > 0) {
            [fetchResult enumerateObjectsUsingBlock:^(PHAsset *PHAsset, NSUInteger index, BOOL *stop) {
                if (PHAsset != nil) {
                    NBUAsset *asset = [NBUAsset assetForPHAsset:PHAsset];
                    [assets addObject:asset];

                    if (assets.count == [fetchResult count]) {
                        resultBlock(assets, YES, nil);
                    }
                }
            }];
        } else {
            resultBlock([[NSArray alloc] init], YES, nil);
        }

        return;
    }
}

#pragma mark 获取所有类型的资源

- (void)allAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock {
    [self allAssetsWithTypes:NBUAssetTypeAny
                 resultBlock:resultBlock];
}

#pragma mark 获取图片资源

- (void)allImageAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock {
    [self allAssetsWithTypes:NBUAssetTypeImage
                 resultBlock:resultBlock];
}

#pragma mark 获取视频资源

- (void)allVideoAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock {
    [self allAssetsWithTypes:NBUAssetTypeVideo
                 resultBlock:resultBlock];
}

#pragma mark - 保存相片到相册 Save to library
#pragma mark 保存相片到相册----方法内部区分系统版本

- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
                  resultBlock:(NBUAssetURLResultBlock)resultBlock {
    [self saveImageToCameraRoll:image
                       metadata:metadata
       addToAssetsGroupWithName:nil
                    resultBlock:resultBlock];
}

#pragma mark 保存相片到相册----方法内部区分系统版本

- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
     addToAssetsGroupWithName:(NSString *)name
                  resultBlock:(NBUAssetURLResultBlock)resultBlock {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {// 8.0以上系统保存图片到相册
        if (name.length == 0) {
            name = @"Camera Roll";
        }
        [self groupWithName:name resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = nil;
                if (group == nil) {// 相册不存在 , 创建相册
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
                } else {
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[group PHAssetCollection]];
                }

                // 保存图片
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
            }                                 completionHandler:^(BOOL success, NSError *error) {
                if (resultBlock) {
                    resultBlock(nil, error);
                }
                if (!success) {
                    NBULogInfo(@"Error creating album: %@", error);
                }
            }];
        }];
        return;
    }// 8.0以上系统保存图片到相册
}


@end

