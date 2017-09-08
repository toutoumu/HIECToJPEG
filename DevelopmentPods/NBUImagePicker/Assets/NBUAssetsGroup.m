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
#import <AssetsLibrary/AssetsLibrary.h>
@import Photos;
@class NBUAssetUtils;
#import "NBUAssetUtils.h"
#import "RNCryptor.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
//#import "RNCryptorEngine.h"

// Private classes
/// 8.x以下系统使用
@interface NBUALAssetsGroup : NBUAssetsGroup

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)ALAssetsGroup;

@end

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

-(void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL,NBUAsset *))reslutBlock{
    if (reslutBlock) {
        reslutBlock(nil,YES,nil);
    }
}

/// 8.x以上系统使用
+ (NBUAssetsGroup *)groupForPHAssetsGroup:(PHAssetCollection *)PHAssetCollection
{
    return [[NBUPHAssetsGroup alloc] initWithPHAssetCollection:PHAssetCollection];
}
/// 8.x以下系统使用
+ (NBUAssetsGroup *)groupForALAssetsGroup:(ALAssetsGroup *)ALAssetsGroup
{
    return [[NBUALAssetsGroup alloc] initWithALAssetsGroup:ALAssetsGroup];
}
/// 沙箱文件系统使用
+ (NBUAssetsGroup *)groupForDirectoryURL:(NSURL *)directoryURL
                                    name:(NSString *)name
{
    return [[NBUDirectoryAssetsGroup alloc] initWithDirectoryURL:directoryURL
                                                            name:name];
}

// *** Implement in subclasses if needed ***

- (NSString *)name { return nil; }

- (BOOL)isEditable { return NO; }

- (NSURL *)URL { return nil; }

- (UIImage *)posterImage { return nil; }

- (NBUAssetsGroupType)type { return NBUAssetsGroupTypeUnknown; }

- (ALAssetsGroup *)ALAssetsGroup { return nil; }

- (PHAssetCollection *)PHAssetCollection { return nil; }

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock {}

- (void)stopLoadingAssets {}

/// 8.x以下系统,(系统相册已有图片)添加加图片到相册组
- (BOOL)addAsset:(NBUAsset *)asset { return NO; }

/// 8.x以下系统,(系统相册已有图片)添加加图片到相册组
- (void)addAssetWithURL:(NSURL *)assetURL
            resultBlock:(void (^)(BOOL))resultBlock {}

- (NSUInteger)assetsCount { return 0; }

- (NSUInteger)imageAssetsCount { return 0; }

- (NSUInteger)videoAssetsCount { return 0; }

@end


#pragma mark - 8.x以下系统相册
@implementation NBUALAssetsGroup
{
    NSString * _persistentID;
    BOOL _stopLoadingAssets;
    NSUInteger _lastAssetsCount;
}

@synthesize name = _name;
@synthesize editable = _editable;
@synthesize URL = _URL;
@synthesize type = _type;
@synthesize ALAssetsGroup = _ALAssetsGroup;

- (instancetype)initWithALAssetsGroup:(ALAssetsGroup *)ALAssetsGroup
{
    self = [super init];
    if (self)
    {
        if (ALAssetsGroup)
        {
            self.ALAssetsGroup = ALAssetsGroup;
            
            // 注释掉监听 Observe library changes
            /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(libraryChanged:)
                                                         name:ALAssetsLibraryChangedNotification
                                                       object:nil];*/
        }
        else
        {
            // Group is required
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    // 注释掉监听 Stop observing
    // [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; %@; editable = %@>",
            NSStringFromClass([self class]), self, _ALAssetsGroup, NBUStringFromBOOL(_editable)];
}


- (void)libraryChanged:(NSNotification *)notification
{
    //    NBULogVerbose(@"Assets group %@ posterImage: %@", _name, _ALAssetsGroup.posterImage);
    //    NBULogVerbose(@"Assets group %@ nAssets: %d", _name, _ALAssetsGroup.numberOfAssets);
    //    NBULogVerbose(@"Assets group %@ ALAssetsGroupPropertyName: %@", _name, [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyName]);
    //    NBULogVerbose(@"Assets group %@ ALAssetsGroupPropertyType: %@", _name, [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyType]);
    //    NBULogVerbose(@"Assets group %@ ALAssetsGroupPropertyPersistentID: %@", _name, [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID]);
    
    // Is ALAssetsGroup is still valid?
    if ([_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyName])
    {
        // Assets count changed?
        NSUInteger newCount = self.imageAssetsCount;
        if (newCount != _lastAssetsCount)
        {
            NBULogVerbose(@"Assets group %@ count changed: %@ -> %@", _name, @(_lastAssetsCount), @(newCount));
            
            _lastAssetsCount = newCount;
            
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [[NSNotificationCenter defaultCenter] postNotificationName:NBUObjectUpdatedNotification
                                                                                   object:self];
                           });
        }
        return;
    }
    
    // Not valid -> Reload ALAssetsGroup
    // Retrieve
    [[NBUAssetsLibrary sharedLibrary].ALAssetsLibrary groupForURL:_URL
                                                      resultBlock:^(ALAssetsGroup * ALAssetsGroup)
     {
         if (ALAssetsGroup)
         {
             NBULogVerbose(@"Assets group %@ had to be reloaded", _name);
             
             NSUInteger oldCount = _lastAssetsCount;
             _ALAssetsGroup = ALAssetsGroup;
             
             // Send update notification only if needed!
             if (oldCount != _lastAssetsCount)
             {
                 NBULogVerbose(@"Assets group %@ count changed: %@ -> %@",
                               _name, @(oldCount), @(self.imageAssetsCount));
                 
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:NBUObjectUpdatedNotification
                                                                                        object:self];
                                });
             }
         }
         else
         {
             NBULogWarn(@"Assets group %@ couldn't be reloaded. It may no longer exist", _name);
         }
     }
                                                     failureBlock:^(NSError * error)
     {
         NBULogError(@"Error while reloading assets group %@: %@", _name, error);
     }];
}

#pragma mark - Properties

- (void)setALAssetsGroup:(ALAssetsGroup *)ALAssetsGroup
{
    _ALAssetsGroup = ALAssetsGroup;
    
    _name = [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyName];
    _type = [[_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
    _persistentID = [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyPersistentID];
    _lastAssetsCount = self.imageAssetsCount;
    
    _editable = _ALAssetsGroup.editable;
    _URL = [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyURL];
}

- (UIImage *)posterImage
{
    return [UIImage imageWithCGImage:[_ALAssetsGroup posterImage]];
}

#pragma mark - Assets

- (void)stopLoadingAssets
{
    _stopLoadingAssets = YES;
}

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock
{
    // Set the group's asset filter
    ALAssetsFilter * filter;
    NSUInteger countToReach;
    switch (types)
    {
        case NBUAssetTypeImage:
        {
            filter = [ALAssetsFilter allPhotos];
            countToReach = self.imageAssetsCount;
            break;
        }
        case NBUAssetTypeVideo:
        {
            filter = [ALAssetsFilter allVideos];
            countToReach = self.videoAssetsCount;
            break;
        }
        case NBUAssetTypeAny:{
            filter = [ALAssetsFilter allAssets];
            countToReach = self.assetsCount;
            break;
        }
        default:
        {
            filter = nil;
            countToReach = self.assetsCount;
            break;
        }
    }
    [_ALAssetsGroup setAssetsFilter:filter];
    
    // Nothing to enumerate?
    NSMutableArray * assets = [NSMutableArray array];
    if (countToReach == 0)
    {
        resultBlock(assets, YES, nil);
        return;
    }
    
    // Incremental load size
    loadSize = loadSize ? loadSize : NSUIntegerMax;
    
    // Enumeration block
    _stopLoadingAssets = NO;
    ALAssetsGroupEnumerationResultsBlock block = ^(ALAsset * ALAsset,
                                                   NSUInteger index,
                                                   BOOL * stop)
    {
        // 判断是否需要停止加载数据,Should we stop?
        if (_stopLoadingAssets)
        {
            * stop = YES;
            return;
        }
        
        // 处理当前的图片信息,Process next asset
        if (ALAsset)
        {
            NBUAsset * asset = [NBUAsset assetForALAsset:ALAsset];
            [assets addObject:asset];
            
            // 是否已经加载了loadSize的整数倍,Incremental load reached?
            if ((assets.count % loadSize) == 0 &&
                assets.count != countToReach)
            {
                NBULogVerbose(@"%@ Incrementally loaded: %@ assets", _name, @(assets.count));
                
                resultBlock(assets, NO, nil);
            }
        }
        
        // 全部加载完成Finish
        else
        {
            if (_stopLoadingAssets)
            {
                NBULogInfo(@"Stoppped retrieving assets");
            }
            else
            {
                NBULogVerbose(@"Loading '%@' finished: %@ assets with filter %@", _name, @(assets.count), filter);
                if (assets.count != countToReach)
                {
                    NBULogWarn(@"iOS bug: AssetsLibrary returned only %@ assets but numberOfAssets was %@.",
                               @(assets.count), @(countToReach));
                }
                
                resultBlock(assets, YES, nil);
            }
        }
    };
    
    // Enumerate
    NBULogVerbose(@"Start loading %@ assets...", _name);
    if (!indexSet)
    {
        [_ALAssetsGroup enumerateAssetsWithOptions:reverseOrder ? NSEnumerationReverse : 0
                                        usingBlock:block];
    }
    else
    {
        [_ALAssetsGroup enumerateAssetsAtIndexes:indexSet
                                         options:reverseOrder ? NSEnumerationReverse : 0
                                      usingBlock:block];
    }
}

- (NSUInteger)assetsCount
{
    [_ALAssetsGroup setAssetsFilter:nil];
    return (NSUInteger)[_ALAssetsGroup numberOfAssets];
}

- (NSUInteger)imageAssetsCount
{
    [_ALAssetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    return (NSUInteger)[_ALAssetsGroup numberOfAssets];
}

- (NSUInteger)videoAssetsCount
{
    [_ALAssetsGroup setAssetsFilter:[ALAssetsFilter allVideos]];
    return (NSUInteger)[_ALAssetsGroup numberOfAssets];
}

- (BOOL)addAsset:(NBUAsset *)asset
{
    if ([_ALAssetsGroup addAsset:asset.ALAsset])
    {
        NBULogInfo(@"Added asset: %@ to group: %@", asset, self);
        return YES;
    }
    else
    {
        NBULogWarn(@"Failed to add asset: %@ to group: %@", asset, self);
        return NO;
    }
}

- (void)addAssetWithURL:(NSURL *)assetURL
            resultBlock:(void (^)(BOOL))resultBlock
{
    [[NBUAssetsLibrary sharedLibrary] assetForURL:assetURL
                                      resultBlock:^(NBUAsset * imageAsset,
                                                    NSError * error)
     {
         if (!imageAsset)
         {
             if (resultBlock) resultBlock(NO);
         }
         else
         {
             BOOL success = [self addAsset:imageAsset];
             if (resultBlock) resultBlock(success);
         }
     }];
}

@end



#pragma mark - 8.x以上系统相册
@implementation NBUPHAssetsGroup
{
    NSString * _persistentID;
    BOOL _stopLoadingAssets;
    NSUInteger _lastAssetsCount;
    // 加载结果缓存
    PHFetchResult *assetsFetchResults;
    
}

@synthesize name = _name;
@synthesize editable = _editable;
@synthesize URL = _URL;
@synthesize type = _type;
@synthesize PHAssetCollection = _PHAssetCollection;
@synthesize imageAssetsCount = _imageAssetsCount;
@synthesize videoAssetsCount = _videoAssetsCount;
@synthesize assetsCount = _assetsCount;
@synthesize posterImage = _posterImage;




-(void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL, NBUAsset *))reslutBlock{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        NSMutableArray *arrays= [[NSMutableArray alloc]init];
        for (NBUAsset *asset in array) {
            [arrays addObject:asset.PHAsset];
        }
        [PHAssetChangeRequest deleteAssets: arrays];
    } completionHandler:^(BOOL success, NSError *error) {
        if (reslutBlock) {
            if (error) {// 出错代表操作结束
                reslutBlock(error, YES , nil);
                NBULogInfo(@"Error: %@", error);
                return ;
            }else{
                for (NBUAsset* file in array) {//通知客户端删除文件
                    reslutBlock(nil,NO,file);
                }
            }
            reslutBlock(nil, YES, nil);//通知客户端操作完成
        }
    }];
}

- (instancetype)initWithPHAssetCollection:(PHAssetCollection *)PHAssetCollection
{
    self = [super init];
    if (self)
    {
        if (PHAssetCollection)
        {
            self.PHAssetCollection = PHAssetCollection;
            // 注册监听
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
        else
        {
            // Group is required
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    // 注销监听
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; %@; editable = %@>",
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
            if (newCount != _lastAssetsCount)
            {
                NBULogVerbose(@"Assets group %@ count changed: %@ -> %@", _name, @(_lastAssetsCount), @(newCount));
                
                _lastAssetsCount = newCount;
                
                dispatch_async(dispatch_get_main_queue(), ^
                               {
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
- (void)setPHAssetCollection:(PHAssetCollection *)PHAssetCollection{
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
    _editable = [_PHAssetCollection canPerformEditOperation:PHCollectionEditOperationDeleteContent] ||[_PHAssetCollection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
    //已经不再使用了 _URL = [_ALAssetsGroup valueForProperty:ALAssetsGroupPropertyURL];
}

#pragma mark 封面照片
- (UIImage *)posterImage{
    return  _posterImage;
}

#pragma mark - Assets
#pragma mark 停止加载
- (void)stopLoadingAssets{
    _stopLoadingAssets = YES;
}

#pragma mark 加载相册图片
- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock
{
    NSUInteger countToReach = self.imageAssetsCount;
    // 如果已经加载过
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    if (reverseOrder) {//反转--倒序
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    }else{//升序
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    }
    switch (types) {//类型
        case NBUAssetTypeImage: {//图片
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
            assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults  countOfAssetsWithMediaType:PHAssetMediaTypeImage];
            break;
        }
        case NBUAssetTypeVideo: {//视频
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeVideo];
            assetsFetchResults  = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults  countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
            break;
        }
        default:{//全部
            assetsFetchResults  = [PHAsset fetchAssetsInAssetCollection:_PHAssetCollection options:options];
            countToReach = [assetsFetchResults  count];
        }
    }
    NSMutableArray * assets = [NSMutableArray array];
    if (countToReach == 0)
    {
        resultBlock(assets, YES, nil);
        return;
    }
    
    // Incremental load size
    loadSize = loadSize ? loadSize : NSUIntegerMax;
    
    // Enumeration block
    _stopLoadingAssets = NO;
    void (^myblock)(PHAsset *PHAsset, NSUInteger index, BOOL *stop) = ^(PHAsset * PHAsset, NSUInteger index, BOOL * stop){
        // Should we stop?
        if (_stopLoadingAssets)
        {
            * stop = YES;
            return;
        }
        
        if (PHAsset != nil) {
            NBUAsset * asset = [NBUAsset assetForPHAsset:PHAsset];
            [assets addObject:asset];
            
            // Incremental load reached?
            if ((assets.count % loadSize) == 0 && assets.count != countToReach)
            {
                NBULogVerbose(@"%@ Incrementally loaded: %@ assets", _name, @(assets.count));
                
                resultBlock(assets, NO, nil);
            }else if(assets.count == countToReach){
                resultBlock(assets, YES, nil);
            }
        }
        // 全部加载完成Finish
        else
        {
            if (_stopLoadingAssets)
            {
                NBULogInfo(@"Stoppped retrieving assets");
            }
            else
            {
                NBULogVerbose(@"Loading '%@' finished: %@ assets with options %@", _name, @(assets.count), options);
                if (assets.count != countToReach)
                {
                    NBULogWarn(@"iOS bug: AssetsLibrary returned only %@ assets but numberOfAssets was %@.",
                               @(assets.count), @(countToReach));
                }
                
                resultBlock(assets, YES, nil);
            }
        }
    };
    
    if (!indexSet)
    {
        [assetsFetchResults enumerateObjectsUsingBlock:myblock];
    }
    else
    {
        [assetsFetchResults enumerateObjectsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:myblock];
        
    }
}
@end





#pragma mark - 沙盒相册
@implementation NBUDirectoryAssetsGroup
{
    NSArray * _directoryContents;
    BOOL _stopLoadingAssets;
}


@synthesize name = _name;
@synthesize URL = _URL;
@synthesize type = _type;
@synthesize posterImage = _posterImage;

+ (void)initialize
{
    if (self == [NBUDirectoryAssetsGroup class])
    {
    }
}
-(void)deleteAll:(NSArray *)array withBlock:(void (^)(NSError *, BOOL ,NBUAsset *))reslutBlock{
    // 检查数据
    if (array == nil || array.count ==0) {
        if (reslutBlock != nil) {
            reslutBlock([[NSError alloc] initWithDomain:@"没有数据" code:10 userInfo:nil], YES ,nil);
        }
        return;
    }
    
    BOOL exsist = NO;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];

    for (NBUFileAsset *file in array) {
        if (file.URL == nil || file.URL.path == nil) {
            error = [[NSError alloc] initWithDomain:@"数据错误" code:11 userInfo:nil];
            break;
        }
        // 原图
        exsist = [manager fileExistsAtPath:file.URL.path];
        if (exsist) {
            [manager removeItemAtPath:file.URL.path error:&error];
            if (error != nil) {
                break;
            }
        }
        
        // 缩略图
        exsist = [manager fileExistsAtPath:file.thumbnailImagePath];
        if (exsist) {
            [manager removeItemAtPath:file.thumbnailImagePath error:&error];
            if (error != nil) {
                break;
            }
        }
        
        // 全屏图片
        exsist = [manager fileExistsAtPath:file.fullScreenImagePath];
        if (exsist) {
            [manager removeItemAtPath:file.fullScreenImagePath error:&error];
            if (error != nil) {
                break;
            }
        }
        // 成功删除一个文件的回调
        if(reslutBlock != nil)
        {
            reslutBlock(error,false,file);
        }
    }
    if (error != nil) {
        NBULogInfo(@"Error: %@", error);
    }
    // 操作执行完成,无论有没有完成操作都需要回调
    if (reslutBlock != nil) {
        reslutBlock(error, YES, nil);
    }
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL
                                name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        _name = name ? name : [directoryURL.lastPathComponent stringByDeletingPathExtension];
        _URL = directoryURL;
        _type = NBUAssetsGroupTypeDirectory;
        
        // Initialize
        [self refreshDirectoryContents];
        if (_directoryContents.count > 0)
        {
            
            NSURL * posterFileURL = _directoryContents[_directoryContents.count - 1];
            //if ([posterFileURL.path hasSuffix:@"mov"]) {
            // 修改为全部取缩略图
            posterFileURL = [[NSURL alloc] initFileURLWithPath: [[directoryURL.path stringByAppendingPathComponent:NBUFileAsset.thumbnailDir] stringByAppendingPathComponent:posterFileURL.path.lastPathComponent]];
            //}
            if(![@"Decrypted" isEqualToString:name]){//如果是需要解密的数据
                // 解密数据
                NSError *error = nil;
                NSData *inData = [NSData dataWithContentsOfURL:posterFileURL];
                NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:[NBUAssetUtils getPassword] error:&error];
                if(error == nil){
                    _posterImage = [UIImage imageWithData:outData];
                }                
            }else{
                _posterImage = [[UIImage imageWithContentsOfFile:posterFileURL.path] thumbnailWithSize:[NBUAsset thumbnailSize]];
            }
        }
    }
    return self;
}

- (void)refreshDirectoryContents
{
    _directoryContents = [[NSFileManager defaultManager] URLsForFilesWithExtensions:kNBUImageFileExtensions
                                                              searchInDirectoryURLs:@[_URL]];
}

- (NSUInteger)assetsCount
{
    return _directoryContents.count;
}

- (NSUInteger)imageAssetsCount
{
    return self.assetsCount;
}

- (NSUInteger)videoAssetsCount
{
    return 0; // For now
}

- (void)stopLoadingAssets
{
    _stopLoadingAssets = YES;
}

- (void)assetsWithTypes:(NBUAssetType)types
              atIndexes:(NSIndexSet *)indexSet
           reverseOrder:(BOOL)reverseOrder
    incrementalLoadSize:(NSUInteger)loadSize
            resultBlock:(NBUAssetsResultBlock)resultBlock
{
    [self refreshDirectoryContents];
    
    // Adjust order and indexes (if any)
    NSArray * contents = reverseOrder ? _directoryContents.reverseObjectEnumerator.allObjects : _directoryContents;
    if (indexSet)
    {
        contents = [contents objectsAtIndexes:indexSet];
    }
    
    // Async create assets
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       [self assetsWithFileURLs:contents
                            incrementalLoadSize:loadSize
                                    resultBlock:resultBlock];
                   });
}

- (void)assetsWithFileURLs:(NSArray *)fileURLs
       incrementalLoadSize:(NSUInteger)loadSize
               resultBlock:(NBUAssetsResultBlock)resultBlock
{
    NSMutableArray * assets = [NSMutableArray arrayWithCapacity:fileURLs.count];
    
    // Create assets for each item
    _stopLoadingAssets = NO;
    for (NSURL * fileURL in fileURLs)
    {
        // Stop?
        if (_stopLoadingAssets)
        {
            _stopLoadingAssets = NO;
            return;
        }
        
        [assets addObject:[NBUAsset assetForFileURL:fileURL]];
        
        // Return incrementally?
        if (loadSize &&
            (assets.count % loadSize) == 0 &&
            assets.count != fileURLs.count)
        {
            resultBlock(assets, NO, nil);
        }
    }
    
    resultBlock(assets, YES, nil);
}

@end

