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
@import Photos;


NSString * const NBUAssetsErrorDomain = @"NBUAssetsErrorDomain";

static NBUAssetsLibrary * _sharedLibrary = nil;

@implementation NBUAssetsLibrary
{
    NSMutableDictionary * _directories;// 沙盒相册集合
}

#pragma mark - Initialization

+ (NBUAssetsLibrary *)sharedLibrary
{
    if (!_sharedLibrary)
    {
        [NBUAssetsLibrary new];
    }
    return _sharedLibrary;
}

+ (void)setSharedLibrary:(NBUAssetsLibrary *)library
{
    _sharedLibrary = library;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _ALAssetsLibrary = [ALAssetsLibrary new];
        _PHCachingImageManager = [[PHCachingImageManager alloc]init];
        _directories = [NSMutableDictionary dictionary];
        
        // Set the first object as the singleton
        if (!_sharedLibrary)
        {
            _sharedLibrary = self;
        }
        
        // Observe library changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(libraryChanged:)
                                                     name:ALAssetsLibraryChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    // Stop observing
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ALAssetsLibraryChangedNotification
                                                  object:nil];
}

/// 导出相片到系统相册 ---- 区分系统版本
+(void)addAll:(NSArray *)array toAlbum:(NSString*)albumName withBlock:(void (^)(NSError *, BOOL,int))resultBlock{
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 尝试获取相册
        [[NBUAssetsLibrary sharedLibrary] groupWithName:albumName resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            PHAssetCollection *collection = nil;//相册
            if (group != nil) {
                collection = [group PHAssetCollection];
            }else {//相册不存在, 创建相册
                __block NSString *collectionId = nil;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *assetCollectionChangeRequest = nil;
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
                    collectionId =[assetCollectionChangeRequest placeholderForCreatedAssetCollection].localIdentifier;
                } error: &error ];
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
            for (NBUFileAsset* image in array) {
                i++;
                if (resultBlock) {//操作过程中,报告进度
                    resultBlock(nil,false,i);
                }
                // 由于使用一次请求添加多张照片会导致内存溢出,因此这里采取的是 每次一张图片都单独做一个请求来保存
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: collection];
                    if (image.type == NBUAssetTypeImage) {//图片
                        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[image.fullResolutionImage imageWithOrientationUp]];
                        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
                    }else{//视频
                        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:image.URL];
                        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
                    }
                } error:&error];
                if (error != nil) {//执行出错
                    resultBlock(error,YES,i);
                    NBULogInfo(@"Error creating asset: %@", error);
                    return;
                }
            }
            if (resultBlock) {//操作完成
                resultBlock(error,YES,array.count);
            }
            
            
            //            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //                PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: collection];
            //                int i = 0;
            //                for (UIImage *image in array) {
            //                    i ++;
            //                    PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[image imageWithOrientationUp]];
            //                    [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
            //                    if (resultBlock) {//操作过程中
            //                        resultBlock(nil,false,i);
            //                    }
            //                }
            //            } completionHandler:^(BOOL success, NSError *error) {
            //                if (resultBlock) {//操作完成
            //                    resultBlock(error,YES,array.count);
            //                }
            //                
            //                if (!success) {
            //                    NBULogInfo(@"Error creating asset: %@", error);
            //                }
            //            }];
        }];
        return;
    }
    else{// IOS 8.0一下系统,导出照片到相册, 未测试代码
        [NBUAssetsLibrary export:array atIndex:0 albumName:albumName withBlock: resultBlock];
    }
}

/// 8.0以下系统需要的递归导出方法
+(void)export:(NSArray * )data atIndex :(int)index albumName:(NSString*)albumName withBlock:(void (^)(NSError *, BOOL,int))resultBlock{
    // 如果已经循环到最后一项
    if (index < 0 || index > data.count -1) {
        if(index == data.count){//导出或解密成功
            if (resultBlock) {
                resultBlock(nil, YES, data.count);
            }
        }
        return;
    }
    
    NBUFileAsset *image = [data objectAtIndex:index];
    [[NBUAssetsLibrary sharedLibrary] createAlbumGroupWithName:albumName resultBlock:^(NBUAssetsGroup * groups,NSError *errors){
        [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll:[image.fullResolutionImage imageWithOrientationUp] metadata:nil addToAssetsGroupWithName:albumName resultBlock:^(NSURL *url,NSError *error){
            if (error == nil) {
                [self export:data atIndex:index + 1 albumName:albumName withBlock:resultBlock];
                if (resultBlock) {
                    resultBlock(nil,NO,index);
                }
            }else{
                resultBlock(error,YES,index);
            }
        }];
    }];
}




#pragma mark 注册沙盒中的相册
- (void)registerDirectoryGroupforURL:(NSURL *)directoryURL
                                name:(NSString *)name
{
    _directories[directoryURL] = name ? name : [NSNull null];
}

- (void)libraryChanged:(NSNotification *)notification
{
    NBULogVerbose(@"Library changed: %@ userInfo: %@", notification, notification.userInfo);
}

#pragma mark - Access permissions

- (BOOL)userDeniedAccess
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        // Check with ALAssetsLibrary
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied;
    }
    else
    {
        // Check with ALAssetsLibrary
        return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied;
    }
}

- (BOOL)restrictedAccess
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
    {
        // Check with ALAssetsLibrary
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted;
    }
    else
    {
        // Check with ALAssetsLibrary
        return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted;
    }
}

#pragma mark - 相册相关操作 Retrieving asset groups
#pragma mark 加载所有的沙盒中的目录
- (void)directoryGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock
{
    // 异步加载沙盒中的目录
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       NSMutableArray * groups = [NSMutableArray array];
                       id name;
                       for (NSURL * directoryURL in _directories)
                       {
                           name = _directories[directoryURL];
                           [groups addObject:[NBUAssetsGroup groupForDirectoryURL:directoryURL
                                                                             name:name == [NSNull null] ? nil : name]];
                       }
                       resultBlock(groups, nil);
                   });
}

#pragma mark 加载沙盒&系统相册
- (void)allGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock
{
    NSMutableArray * groups = [NSMutableArray array];
    
    // 加载所有的沙盒中的目录 First all directory groups
    [self directoryGroupsWithResultBlock:^(NSArray * directoryGroups,
                                           NSError * directoryError)
     {
         if (directoryGroups)
         {
             [groups addObjectsFromArray:directoryGroups];
         }
         
         // 加载系统相册 Then all AL albums
         [self albumGroupsWithResultBlock:^(NSArray * albumGroups,
                                            NSError * albumError)
          {
              if (albumGroups)
              {
                  [groups addObjectsFromArray:albumGroups];
              }
              
              resultBlock(groups, albumError);
          }];
     }];
}

#pragma mark 8.x以下系统,加载胶卷相册---这个相册只能有一个
- (void)cameraRollGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    [self groupsWithTypes:ALAssetsGroupSavedPhotos
              resultBlock:^(NSArray * groups, NSError * error) { resultBlock([groups lastObject], error); }];
}
#pragma mark 8.x以下系统,加载照片流
- (void)photoStreamGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    [self groupsWithTypes:ALAssetsGroupPhotoStream
              resultBlock:^(NSArray * groups, NSError * error) { resultBlock([groups lastObject], error); }];
}

#pragma mark 8.x以下系统,加载图片库---这个相册只能有一个
- (void)photoLibraryGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    [self groupsWithTypes:ALAssetsGroupLibrary
              resultBlock:^(NSArray * groups, NSError * error) { resultBlock([groups lastObject], error); }];
}

#pragma mark 加载所有系统相册(胶卷&照片流&图片库)----方法内部区分系统版本
- (void)albumGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock
{
    NSMutableArray * groups = [NSMutableArray array];
    // 8.0以上系统使用
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 列出所有相册智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop){
            [groups addObject:[NBUAssetsGroup groupForPHAssetsGroup:obj]];
            NBULogInfo(@"相册名称:%@",obj.localizedTitle);
        }];
        
        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [topLevelUserCollections enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop){
            NBULogInfo(@"相册名称:%@",obj.localizedTitle);
            [groups addObject:[NBUAssetsGroup groupForPHAssetsGroup:obj]];
        }];
        resultBlock(groups,nil);
     }
    else{ // 8.0以下系统使用
        // 加载胶卷相册 Add camera roll
        [self cameraRollGroupWithResultBlock:^(NBUAssetsGroup * cameraRollGroup, NSError * error1)
         {
             if (error1 && (error1.code == ALAssetsLibraryAccessUserDeniedError ||      // User denied access
                            error1.code == ALAssetsLibraryAccessGloballyDeniedError))   // Location is not enabled
             {
                 // No need to continue
                 resultBlock(nil, error1);
                 return;
             }
             if (cameraRollGroup)
             {
                 [groups addObject:cameraRollGroup];
             }
             
             // 加载图片库 Add photo library
             [self photoLibraryGroupWithResultBlock:^(NBUAssetsGroup * photoLibraryGroup, NSError * error2)
              {
                  if (photoLibraryGroup)
                  {
                      [groups addObject:photoLibraryGroup];
                  }
                  
                  // 加载相册 Add albums
                  [self groupsWithTypes:ALAssetsGroupAlbum
                            resultBlock:^(NSArray * albumGroups, NSError * error3)
                   {
                       if (albumGroups)
                       {
                           [groups addObjectsFromArray:albumGroups];
                       }
                       
                       // Finally return groups using the result block
                       resultBlock(groups, nil);
                   }];
              }];
         }];
    }// 8.0以下系统使用
}

#pragma mark 8.x以下系统,按相册类型加载加载相册
- (void)groupsWithTypes:(NBUAssetsGroupType)types
            resultBlock:(NBUAssetsGroupsResultBlock)resultBlock
{
    // Enumeration block
    NSMutableArray * groups = [NSMutableArray array];
    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock = ^(ALAssetsGroup * ALAssetsGroup,
                                                                      BOOL * stop)
    {
        // Process next group
        if (ALAssetsGroup)
        {
            NBUAssetsGroup * group = [NBUAssetsGroup groupForALAssetsGroup:ALAssetsGroup];
            [groups addObject:group];
        }
        
        // Finished
        else
        {
            NBULogInfo(@"Retrieved %@ groups of type %@", @(groups.count), @(types));
            NBULogVerbose(@"Groups: %@", groups);
            resultBlock(groups, nil);
        }
    };
    
    // Failure block
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError * error)
    {
        NBULogError(@"Failed to retrieve type %@ groups: %@", @(types), error);
        resultBlock(nil, error);
    };
    
    // Access library
    [_ALAssetsLibrary enumerateGroupsWithTypes:types
                                    usingBlock:enumerationBlock
                                  failureBlock:failureBlock];
}

#pragma mark 8.x以下系统,根据URL加载相册
- (void)groupForURL:(NSURL *)groupURL
        resultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    NBULogTrace();
    
    // Result block
    ALAssetsLibraryGroupResultBlock block = ^(ALAssetsGroup * ALAssetsGroup)
    {
        if (ALAssetsGroup)
        {
            NBUAssetsGroup * group = [NBUAssetsGroup groupForALAssetsGroup:ALAssetsGroup];
            NBULogVerbose(@"Retrieved group: %@", group);
            resultBlock(group, nil);
        }
        else
        {
            NBULogVerbose(@"No group with URL '%@' was found", groupURL);
            resultBlock(nil, nil);
        }
    };
    
    // Failure block
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError * error)
    {
        NBULogError(@"Failed to retrieve group with URL '%@': %@", groupURL, error);
        resultBlock(nil, error);
    };
    
    // Retrieve
    [_ALAssetsLibrary groupForURL:groupURL
                      resultBlock:block
                     failureBlock:failureBlock];
}

#pragma mark 创建相册,区分系统版本
- (void)createAlbumGroupWithName:(NSString *)name
                     resultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    // 8.0以上系统查找相册
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 尝试查找相册
        [[NBUAssetsLibrary sharedLibrary] groupWithName:name resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            if (error) {// 查找出错
                if (resultBlock) {
                    resultBlock(nil, error);
                }
                return ;
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
                collectionId =[assetCollectionChangeRequest placeholderForCreatedAssetCollection].localIdentifier;} error: &error
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
                    resultBlock(nil ,error);
                }
                return;
            }
            if (collectionId != nil) {// 获取创建的相册
                PHAssetCollection *collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
                if (resultBlock) {
                    resultBlock([NBUAssetsGroup groupForPHAssetsGroup:collection],error);

                }
            }else{
                if (resultBlock) {
                    resultBlock(nil,error);
                }
            }
        }];
        return;
    }
    else{// 8.0以下系统创建相册
        // Failure block
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError * error)
        {
            NBULogWarn(@"Couldn't create group named '%@': %@", name, error);
            if (resultBlock) resultBlock(nil, error);
        };
        
        // Result block
        ALAssetsLibraryGroupResultBlock block = ^(ALAssetsGroup * ALAssetsGroup)
        {
            if (ALAssetsGroup)
            {
                NBUAssetsGroup * group = [NBUAssetsGroup groupForALAssetsGroup:ALAssetsGroup];
                NBULogInfo(@"Created new group: %@", group);
                if (resultBlock) resultBlock(group, nil);
            }
            else
            {
                failureBlock([NSError errorWithDomain:NBUAssetsErrorDomain
                                                 code:NBUAssetsGroupAlreadyExists
                                             userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:
                                                                                     @"Group '%@' already exists", name]}]);
            }
        };
        
        // Try to create
        [_ALAssetsLibrary addAssetsGroupAlbumWithName:name
                                          resultBlock:block
                                         failureBlock:failureBlock];
    }// 8.0以下系统创建相册
}

#pragma mark 根据名称查找相册.区分系统版本
- (void)groupWithName:(NSString *)name
          resultBlock:(NBUAssetsGroupResultBlock)resultBlock
{
    // Enumeration block
    __block BOOL found = NO;
    // 8.0以上系统查找相册
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [topLevelUserCollections enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop){
            NBULogInfo(@"相册名称:%@",obj.localizedTitle);
            if ([obj.localizedTitle isEqualToString:name]) {
                *stop = YES;
                resultBlock([NBUAssetsGroup groupForPHAssetsGroup:obj],nil);
                found = YES;
            }
        }];
        
        if (found) {
            return;
        }
        
        // 列出所有相册智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop){
            NBULogInfo(@"相册名称:%@",obj.localizedTitle);
            if ([obj.localizedTitle isEqualToString:name]) {
                *stop = YES;
                resultBlock([NBUAssetsGroup groupForPHAssetsGroup:obj],nil);
                found = YES;
            }
        }];
        
        if (!found) {
            resultBlock(nil,nil);
        }
        return;
    }
    else{// 8.0以下系统使用
        ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock = ^(ALAssetsGroup * ALAssetsGroup,
                                                                          BOOL * stop)
        {
            // Process next group
            if (ALAssetsGroup)
            {
                // Check name
                if ([(NSString *)[ALAssetsGroup valueForProperty:ALAssetsGroupPropertyName] isEqualToString:name])
                {
                    NBUAssetsGroup * group = [NBUAssetsGroup groupForALAssetsGroup:ALAssetsGroup];
                    NBULogVerbose(@"Retrieved group %@", group);
                    *stop = YES;
                    found = YES;
                    resultBlock(group, nil);
                }
            }
            // Finished
            else
            {
                // Wasn't found?
                if (!found)
                {
                    NBULogVerbose(@"No group with name '%@' was found", name);
                    resultBlock(nil, nil);
                }
            }
        };
        
        // Failure block
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError * error)
        {
            NBULogError(@"Failed to search group named '%@': %@", name, error);
            resultBlock(nil, error);
        };
        
        // Access library
        [_ALAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                        usingBlock:enumerationBlock
                                      failureBlock:failureBlock];
    }// 8.0以下系统使用
}



#pragma mark - 图片操作 Retrieve assets
#pragma mark 根据传入的类型获取文件 图片,视频,或全部类型
- (void)allAssetsWithTypes:(NBUAssetType)types
               resultBlock:(NBUAssetsResultBlock)resultBlock;
{
    NBULogVerbose(@"All assets with type %@...", @(types));
    
    NSMutableArray * assets = [NSMutableArray array];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {//代码未测试
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        switch (types) {//类型
            case NBUAssetTypeImage: {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
                break;
            }
            case NBUAssetTypeVideo: {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeVideo];
                break;
            }
            default:{
                break;
            }
        }
        
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
        if ([fetchResult count] > 0) {
            [fetchResult enumerateObjectsUsingBlock:^(PHAsset * PHAsset, NSUInteger index, BOOL * stop){
                if (PHAsset != nil) {
                    NBUAsset * asset = [NBUAsset assetForPHAsset:PHAsset];
                    [assets addObject:asset];
                    
                    if(assets.count == [fetchResult count]){
                        resultBlock(assets, YES, nil);
                    }
                }
            }];
        }else{
            resultBlock([[NSArray alloc]init],YES,nil);
        }
        
        return;
    }
    
    // Add camera roll assets
    [self cameraRollGroupWithResultBlock:^(NBUAssetsGroup * cameraRollGroup,
                                           NSError * error1)
     {
         if (error1 && (error1.code == ALAssetsLibraryAccessUserDeniedError ||      // User denied access
                        error1.code == ALAssetsLibraryAccessGloballyDeniedError))   // Location is not enabled
         {
             // No need to continue
             resultBlock(nil, YES, error1);
             return;
         }
         if (cameraRollGroup)
         {
             [cameraRollGroup assetsWithTypes:types
                                    atIndexes:nil
                                 reverseOrder:NO
                          incrementalLoadSize:0
                                  resultBlock:^(NSArray * cameraRollAssets,
                                                BOOL finished,
                                                NSError * error2)
              {
                  NBULogVerbose(@"All assets: adding %@ from camera roll...", @(cameraRollAssets.count));
                  [assets addObjectsFromArray:cameraRollAssets];
                  
                  // Add photo library assets
                  [self photoLibraryGroupWithResultBlock:^(NBUAssetsGroup * photoLibraryGroup,
                                                           NSError * error3)
                   {
                       if (photoLibraryGroup)
                       {
                           [photoLibraryGroup assetsWithTypes:types
                                                    atIndexes:nil
                                                 reverseOrder:NO
                                          incrementalLoadSize:0
                                                  resultBlock:^(NSArray * photoLibraryAssets,
                                                                BOOL finished,
                                                                NSError * error4)
                            {
                                NBULogVerbose(@"All assets: adding %@ from photo library...", @(photoLibraryAssets.count));
                                [assets addObjectsFromArray:photoLibraryAssets];
                                
                                // Finally return the assets
                                NBULogVerbose(@"All assets: Returning %@ assets", @(assets.count));
                                resultBlock(assets, YES, nil);
                            }];
                       }
                   }];
              }];
         }
     }];
}

#pragma mark 获取所有类型的资源
- (void)allAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock
{
    [self allAssetsWithTypes:NBUAssetTypeAny
                 resultBlock:resultBlock];
}
#pragma mark 获取图片资源
- (void)allImageAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock
{
    [self allAssetsWithTypes:NBUAssetTypeImage
                 resultBlock:resultBlock];
}
#pragma mark 获取视频资源
- (void)allVideoAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock
{
    [self allAssetsWithTypes:NBUAssetTypeVideo
                 resultBlock:resultBlock];
}

#pragma mark 8.x以下系统,根据URL加载资源
- (void)assetForURL:(NSURL *)assetURL
        resultBlock:(NBUAssetResultBlock)resultBlock
{
    // Result block
    ALAssetsLibraryAssetForURLResultBlock block = ^(ALAsset * ALAsset)
    {
        if (ALAsset)
        {
            NBUAsset * asset = [NBUAsset assetForALAsset:ALAsset];
            NBULogVerbose(@"Retrieved asset: %@", asset);
            resultBlock(asset, nil);
        }
        else
        {
            NBULogVerbose(@"No asset for URL '%@' was found", assetURL);
            resultBlock(nil ,nil);
        }
    };
    
    // Failure block
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError * error)
    {
        NBULogError(@"Failed to retrieve asset for URL '%@': %@", assetURL, error);
        resultBlock(nil, error);
    };
    
    // Retrieve
    [_ALAssetsLibrary assetForURL:assetURL
                      resultBlock:block
                     failureBlock:failureBlock];
}

#pragma mark 8.x以下系统,根据URL集合加载资源
-(void)assetsForURLs:(NSArray *)assetURLs
         resultBlock:(NBUAssetsResultBlock)resultBlock
{
    NSMutableArray * assets = [NSMutableArray array];
    NSMutableArray * errors = [NSMutableArray array];
    __block NSUInteger count = 0;
    for (NSURL * assetURL in assetURLs)
    {
        [self assetForURL:assetURL
              resultBlock:^(NBUAsset * imageAsset,
                            NSError * error)
         {
             if (!error)
                 [assets addObject:imageAsset];
             else
                 [errors addObject:error];
             
             // Finished?
             count++;
             if (count == assetURLs.count)
             {
                 // Any errors encountered?
                 NSError * resultError;
                 if (errors.count > 0)
                 {
                     resultError = [NSError errorWithDomain:NBUAssetsErrorDomain
                                                       code:NBUAssetsCouldntRetrieveSomeAssets
                                                   userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:
                                                                                           @"%@ error(s) during assets retrieval",
                                                                                           @(errors.count)],
                                                              NSUnderlyingErrorKey      : errors}];
                 }
                 
                 // Return
                 resultBlock(assets, YES, resultError);
             }
         }];
    }
}


#pragma mark - 保存相片到相册 Save to library
#pragma mark 保存相片到相册----方法内部区分系统版本
- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
                   resultBlock:(NBUAssetURLResultBlock)resultBlock
{
    [self saveImageToCameraRoll:image
                       metadata:metadata
        addToAssetsGroupWithName:nil
                    resultBlock:resultBlock];
}

#pragma mark 保存相片到相册----方法内部区分系统版本
- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
     addToAssetsGroupWithName:(NSString *)name
                  resultBlock:(NBUAssetURLResultBlock)resultBlock
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {// 8.0以上系统保存图片到相册
        if (name.length == 0)
        {
            name = @"Camera Roll";
        }
        [self groupWithName:name resultBlock:^(NBUAssetsGroup *group, NSError *error) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCollectionChangeRequest * assetCollectionChangeRequest = nil;
                if (group == nil) {// 相册不存在 , 创建相册
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name];
                }else{
                    assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: [group PHAssetCollection]];
                }
                
                // 保存图片
                PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
            } completionHandler:^(BOOL success, NSError *error) {
                if (resultBlock) {
                    resultBlock(nil,error);
                }
                if (!success) {
                    NBULogInfo(@"Error creating album: %@", error);
                }
            }];
         }];
        return;
    }// 8.0以上系统保存图片到相册
    else if (SYSTEM_VERSION_LESS_THAN(@"4.1")){// 4.1以下系统保存图片到相册 At least iOS 4.1 required
        NSError * error = [NSError errorWithDomain:NBUAssetsErrorDomain
                                              code:NBUAssetsFeatureNotAvailableInSystem4
                                          userInfo:@{NSLocalizedDescriptionKey : @"Can't save images on iOS 4.0"}];
        NBULogError(@"Failed to save image to Camera Roll. : %@", error);
        if (resultBlock) resultBlock(nil, error);
        return;
    }// 4.1以下系统保存图片到相册 At least iOS 4.1 required
    else{// 8.0以下系统保存图片到相册Save to Camera Roll
        [[NBUAssetsLibrary sharedLibrary].ALAssetsLibrary writeImageToSavedPhotosAlbum:image.CGImage
                                                                              metadata:metadata
                                                                       completionBlock:^(NSURL * assetURL,
                                                                                         NSError * error)
         {
             // Failed?
             if (error)
             {
                 NBULogError(@"Failed to save image to Camera Roll: %@", error);
                 if (resultBlock) resultBlock(nil, error);
             }
             
             // Saved
             else
             {
                 // Call result block
                 NBULogInfo(@"Image saved to Camera Roll with assetURL: %@", assetURL);
                 if (resultBlock) resultBlock(assetURL, nil);
                 
                 // Finished?
                 if (name.length == 0)
                     return;
                 
                 // Check if group already exists
                 [self groupWithName:name
                         resultBlock:^(NBUAssetsGroup * group,
                                       NSError * addToGroupError)
                  {
                      // Exists?
                      if (group)
                      {
                          [group addAssetWithURL:assetURL
                                     resultBlock:NULL]; // No need to check result
                      }
                      
                      // Try to create a group
                      else
                      {
                          [self createAlbumGroupWithName:name
                                             resultBlock:^(NBUAssetsGroup * newGroup,
                                                           NSError * createGroupError)
                           {
                               if (newGroup)
                               {
                                   [newGroup addAssetWithURL:assetURL
                                                 resultBlock:NULL]; // No need to check result
                               }
                           }];
                      }
                  }];
             }
         }];
    }// 8.0以下系统保存图片到相册Save to Camera Roll
}















@end

