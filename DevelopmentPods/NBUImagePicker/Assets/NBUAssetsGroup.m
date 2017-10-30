//
//  NBUAssetsGroup.m
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
// 相册数据模型
#import "NBUAssetsGroup.h"
#import "NBUImagePickerPrivate.h"

@class NBUAssetUtils;

#import "NBUAssetUtils.h"
#import "RNCryptor.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"

// Private classes
/// 8.x以上系统使用
@interface NBUPHAssetsGroup : NBUAssetsGroup <PHPhotoLibraryChangeObserver>

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)PHAssetCollection;

@end

// 沙盒相册,原来是作为私有类使用,现在提取出来放在NBUAssetsGroup.h中作为公有类使用
/*@interface NBUDirectoryAssetsGroup : NBUAssetsGroup
 
 - (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
 name:(NSString *)name;
 
 @end
 */


#pragma mark - 基类NBUAssetsGroup

@implementation NBUAssetsGroup

- (void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL, NBUAsset *))resultBlock {
    if (resultBlock) {
        resultBlock(nil, YES, nil);
    }
}

+ (NBUAssetsGroup *)groupForPHAssetsGroup:(PHAssetCollection *)PHAssetCollection {
    return [[NBUPHAssetsGroup alloc] initWithPHAssetCollection:PHAssetCollection];
}

+ (NBUAssetsGroup *)groupForDirectoryURL:(NSURL *)directoryURL name:(NSString *)name {
    return [[NBUDirectoryAssetsGroup alloc] initWithDirectoryURL:directoryURL name:name];
}

// *** Implement in subclasses if needed ***

- (NSString *)name {return nil;}

- (BOOL)isEditable {return NO;}

- (NSURL *)URL {return nil;}

- (UIImage *)posterImage {return nil;}

- (NBUAssetsGroupType)type {return NBUAssetsGroupTypeUnknown;}

- (PHAssetCollection *)PHAssetCollection {return nil;}

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock {}

- (void)stopLoadingAssets {}

- (NSUInteger)assetsCount {return 0;}

- (NSUInteger)imageAssetsCount {return 0;}

- (NSUInteger)videoAssetsCount {return 0;}

@end


#pragma mark - 8.x以上系统相册

@implementation NBUPHAssetsGroup {
    NSString *_persistentID;
    BOOL _stopLoadingAssets;
    NSUInteger _lastAssetsCount;
    // 加载结果缓存
    PHFetchResult *assetsFetchResults;

}

@synthesize name = _name;
@synthesize editable = _editable;
@synthesize type = _type;
@synthesize PHAssetCollection = _PHAssetCollection;
@synthesize imageAssetsCount = _imageAssetsCount;
@synthesize videoAssetsCount = _videoAssetsCount;
@synthesize assetsCount = _assetsCount;
@synthesize posterImage = _posterImage;


- (void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL, NBUAsset *))resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSMutableArray *arrays = [[NSMutableArray alloc] init];
        for (NBUAsset *asset in array) {
            [arrays addObject:asset.PHAsset];
        }
        [PHAssetChangeRequest deleteAssets:arrays];
    }                                 completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            if (error) {// 出错代表操作结束
                resultBlock(error, YES, nil);
                NBULogInfo(@"Error: %@", error);
                return;
            } else {
                for (NBUAsset *file in array) {//通知客户端删除文件
                    resultBlock(nil, NO, file);
                }
            }
            resultBlock(nil, YES, nil);//通知客户端操作完成
        }
    }];
}

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)PHAssetCollection {
    self = [super init];
    if (self) {
        if (PHAssetCollection) {
            self.PHAssetCollection = PHAssetCollection;
            // 注册监听
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        } else {
            // Group is required
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    // 注销监听
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %@; %@; editable = %@>",
                                      NSStringFromClass([self class]), self, _PHAssetCollection, NBUStringFromBOOL(_editable)];
}

#pragma mark 与8.x之前系统的AlAssets类的libraryChanged对应

- (void)photoLibraryDidChange:(PHChange *)changeInstance {

    // Check if there are changes to the assets we are showing.
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:assetsFetchResults];
    if (collectionChanges == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Get the new fetch result.
        assetsFetchResults = [collectionChanges fetchResultAfterChanges];

        if ([collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
            // Reload the collection view if the incremental diffs are not available
            _imageAssetsCount = [assetsFetchResults countOfAssetsWithMediaType:PHAssetMediaTypeImage];
            _videoAssetsCount = [assetsFetchResults countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
            _assetsCount = _imageAssetsCount + _videoAssetsCount;
            // Assets count changed?
            NSUInteger newCount = self.imageAssetsCount;
            if (newCount != _lastAssetsCount) {
                NBULogVerbose(@"Assets group %@ count changed: %@ -> %@", _name, @(_lastAssetsCount), @(newCount));

                _lastAssetsCount = newCount;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:NBUObjectUpdatedNotification
                                                                        object:self];
                });
            }
            return;
        }

    });
}


#pragma mark - Properties
#pragma mark 重写PHAssetCollection的set方法

- (void)setPHAssetCollection:(PHAssetCollection *)PHAssetCollection {
    // 获取资源数目
    PHFetchResult *fetchResults = [PHAsset fetchAssetsInAssetCollection:PHAssetCollection options:nil];
    _imageAssetsCount = [fetchResults countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    _videoAssetsCount = [fetchResults countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    _assetsCount = _imageAssetsCount + _videoAssetsCount;
    if (_assetsCount > 0) {// 获取封面图片
        PHCachingImageManager *manager = [NBUAssetsLibrary sharedLibrary].PHCachingImageManager;
        [manager requestImageForAsset:fetchResults[0]
                           targetSize:[NBUAsset thumbnailSize]
                          contentMode:PHImageContentModeAspectFill
                              options:nil
                        resultHandler:^(UIImage *result, NSDictionary *info) {
                            _posterImage = result;
                        }];
    }
    _PHAssetCollection = PHAssetCollection;
    _name = _PHAssetCollection.localizedTitle;
    _type = NBUAssetsGroupTypeAlbum;
    _persistentID = _PHAssetCollection.localIdentifier;
    _lastAssetsCount = self.imageAssetsCount;
    // 取值为是否可以移除或者删除
    _editable = [_PHAssetCollection canPerformEditOperation:PHCollectionEditOperationDeleteContent] || [_PHAssetCollection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
}

#pragma mark 封面照片

- (UIImage *)posterImage {
    return _posterImage;
}

#pragma mark - Assets
#pragma mark 停止加载

- (void)stopLoadingAssets {
    _stopLoadingAssets = YES;
}

#pragma mark 加载相册图片

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock {
    NSUInteger countToReach = self.imageAssetsCount;
    // 如果已经加载过
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    // 是否倒序
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:!reverseOrder]];
    switch (types) {//类型
        case NBUAssetTypeImage: {//图片
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
            assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults countOfAssetsWithMediaType:PHAssetMediaTypeImage];
            break;
        }
        case NBUAssetTypeVideo: {//视频
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
            assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
            break;
        }
        default: {//全部
            assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults count];
        }
    }
    NSMutableArray *assets = [NSMutableArray array];
    if (countToReach == 0) {
        resultBlock(assets, YES, nil);
        return;
    }

    // Incremental load size
    loadSize = loadSize ? loadSize : NSUIntegerMax;

    // Enumeration block
    _stopLoadingAssets = NO;
    void (^myBlock)(PHAsset *, NSUInteger, BOOL *) = ^(PHAsset *PHAsset1, NSUInteger index, BOOL *stop) {
        // Should we stop?
        if (_stopLoadingAssets) {
            *stop = YES;
            return;
        }

        if (PHAsset1 != nil) {
            NBUAsset *asset = [NBUAsset assetForPHAsset:PHAsset1];
            [assets addObject:asset];

            // Incremental load reached?
            if ((assets.count % loadSize) == 0 && assets.count != countToReach) {
                NBULogVerbose(@"%@ Incrementally loaded: %@ assets", _name, @(assets.count));

                resultBlock(assets, NO, nil);
            } else if (assets.count == countToReach) {
                resultBlock(assets, YES, nil);
            }
        }
            // 全部加载完成Finish
        else {
            if (_stopLoadingAssets) {
                NBULogInfo(@"Stoppped retrieving assets");
            } else {
                NBULogVerbose(@"Loading '%@' finished: %@ assets with options %@", _name, @(assets.count), options);
                if (assets.count != countToReach) {
                    NBULogWarn(@"iOS bug: AssetsLibrary returned only %@ assets but numberOfAssets was %@.",
                            @(assets.count), @(countToReach));
                }

                resultBlock(assets, YES, nil);
            }
        }
    };

    if (!indexSet) {
        [assetsFetchResults enumerateObjectsUsingBlock:myBlock];
    } else {
        [assetsFetchResults enumerateObjectsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:myBlock];

    }
}
@end


#pragma mark - 沙盒相册

@implementation NBUDirectoryAssetsGroup {
    NSArray *_directoryContents;
    BOOL _stopLoadingAssets;
    NSURL *_URL;
}


@synthesize name = _name;
@synthesize type = _type;
@synthesize posterImage = _posterImage;

+ (void)initialize {
    if (self == [NBUDirectoryAssetsGroup class]) {
    }
}

- (void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL, NBUAsset *))resultBlock {
    // 检查数据
    if (array == nil || array.count == 0) {
        if (resultBlock != nil) {
            resultBlock([[NSError alloc] initWithDomain:@"没有数据" code:10 userInfo:nil], YES, nil);
        }
        return;
    }

    BOOL exist;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];

    for (NBUFileAsset *file in array) {
        if (file.URL == nil || file.URL.path == nil) {
            error = [[NSError alloc] initWithDomain:@"数据错误" code:11 userInfo:nil];
            break;
        }
        // 原图
        exist = [manager fileExistsAtPath:file.URL.path];
        if (exist) {
            [manager removeItemAtPath:file.URL.path error:&error];
            if (error != nil) {
                break;
            }
        }

        // 缩略图
        exist = [manager fileExistsAtPath:file.thumbnailImagePath];
        if (exist) {
            [manager removeItemAtPath:file.thumbnailImagePath error:&error];
            if (error != nil) {
                break;
            }
        }

        // 全屏图片
        exist = [manager fileExistsAtPath:file.fullScreenImagePath];
        if (exist) {
            [manager removeItemAtPath:file.fullScreenImagePath error:&error];
            if (error != nil) {
                break;
            }
        }
        // 成功删除一个文件的回调
        if (resultBlock != nil) {
            resultBlock(error, false, file);
        }
    }
    if (error != nil) {
        NBULogInfo(@"Error: %@", error);
    }
    // 操作执行完成,无论有没有完成操作都需要回调
    if (resultBlock != nil) {
        resultBlock(error, YES, nil);
    }
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
                                name:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name ? name : [directoryURL.lastPathComponent stringByDeletingPathExtension];
        _URL = directoryURL;
        _type = NBUAssetsGroupTypeDirectory;

        // Initialize
        [self refreshDirectoryContents];
        if (_directoryContents.count > 0) {

            NSURL *posterFileURL = _directoryContents[0];
            //if ([posterFileURL.path hasSuffix:@"mov"]) {
            // 修改为全部取缩略图
            posterFileURL = [[NSURL alloc] initFileURLWithPath:[[directoryURL.path stringByAppendingPathComponent:NBUFileAsset.thumbnailDir] stringByAppendingPathComponent:posterFileURL.path.lastPathComponent]];
            //}
            if (![@"Decrypted" isEqualToString:name]) {//如果是需要解密的数据
                // 解密数据
                NSError *error = nil;
                NSData *inData = [NSData dataWithContentsOfURL:posterFileURL];
                NSString *pwd = posterFileURL.lastPathComponent;
                NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:pwd error:&error];
                if (error == nil) {
                    _posterImage = [UIImage imageWithData:outData];
                }
            } else {
                _posterImage = [[UIImage imageWithContentsOfFile:posterFileURL.path] thumbnailWithSize:[NBUAsset thumbnailSize]];
            }
        }
    }
    return self;
}

/**
 * 刷新数据 是否反序(新数据在第一位)
 */
- (void)refreshDirectoryContents {
    if (_directoryContents != nil && _directoryContents.count > 0){
        return;
    }
    NSArray *dirs = [[NSFileManager defaultManager] URLsForFilesWithExtensions:kNBUImageFileExtensions
                                                         searchInDirectoryURLs:@[_URL]];
    // ios 11版本返回的数据是无序的,所以需要排序
    if (@available(iOS 11.0, *)) {
        _directoryContents = [dirs sortedArrayUsingComparator:^(NSURL *obj1, NSURL *obj2) {
            return [obj2.lastPathComponent compare:obj1.lastPathComponent];
        }];
    } else {
        _directoryContents = dirs.reverseObjectEnumerator.allObjects;
    }
}

- (NSUInteger)assetsCount {
    return _directoryContents.count;
}

- (NSUInteger)imageAssetsCount {
    return self.assetsCount;
}

- (NSUInteger)videoAssetsCount {
    return 0; // For now
}

- (void)stopLoadingAssets {
    _stopLoadingAssets = YES;
}

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock {
    [self refreshDirectoryContents];

    // Adjust order and indexes (if any)
    NSArray *contents = !reverseOrder ? _directoryContents.reverseObjectEnumerator.allObjects : _directoryContents;
    if (indexSet) {
        contents = [contents objectsAtIndexes:indexSet];
    }

    // Async create assets
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self assetsWithFileURLs:contents
             incrementalLoadSize:loadSize
                     resultBlock:resultBlock];
    });
}

- (void)assetsWithFileURLs:(NSArray *)fileURLs
       incrementalLoadSize:(NSUInteger)loadSize
               resultBlock:(NBUAssetsResultBlock)resultBlock {
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:fileURLs.count];

    // Create assets for each item
    _stopLoadingAssets = NO;
    for (NSURL *fileURL in fileURLs) {
        // Stop?
        if (_stopLoadingAssets) {
            _stopLoadingAssets = NO;
            return;
        }

        [assets addObject:[NBUAsset assetForFileURL:fileURL]];

        // Return incrementally?
        if (loadSize &&
                (assets.count % loadSize) == 0 &&
                assets.count != fileURLs.count) {
            resultBlock(assets, NO, nil);
        }
    }

    resultBlock(assets, YES, nil);
}

@end


