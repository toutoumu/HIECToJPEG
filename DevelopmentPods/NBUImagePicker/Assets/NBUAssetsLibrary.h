//
//  NBUAssetsLibrary.h
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

@class NBUAssetsGroup, NBUAsset, ALAssetsLibrary;
@import Photos;

/// Supported image asset extensions.
#define kNBUImageFileExtensions @[@"png", @"jpg", @"jpeg", @"tiff", @"tif", @"gif", @"bmp", @"bmpf", @"ico", @"cur", @"xbm" ,@"mov"]

/// NBUAsset return block types.
typedef void (^NBUAssetsGroupsResultBlock)(NSArray * groups, NSError * error);
typedef void (^NBUAssetsGroupResultBlock)(NBUAssetsGroup * group, NSError * error);
typedef void (^NBUAssetsResultBlock)(NSArray * assets, BOOL finished, NSError * error);
typedef void (^NBUAssetResultBlock)(NBUAsset * imageAsset, NSError * error);
typedef void (^NBUAssetURLResultBlock)(NSURL * assetURL, NSError * error);

/// NBUAsset types.
typedef NS_ENUM(NSInteger, NBUAssetType)
{
    NBUAssetTypeUnknown     = 0,
    NBUAssetTypeImage       = 1 << 0,
    NBUAssetTypeVideo       = 1 << 1,
    NBUAssetTypeAny         = (NBUAssetTypeImage |
                               NBUAssetTypeVideo)
};

/// NBUAssetsGroup types.
typedef NS_ENUM(NSInteger, NBUAssetsGroupType)
{
    NBUAssetsGroupTypeUnknown       = 0,
    
    // Groups from ALAssetsLibrary
    NBUAssetsGroupTypeLibrary       = 1 << 0,       // ALAssetsGroupLibrary
    NBUAssetsGroupTypeAlbum         = 1 << 1,       // ALAssetsGroupAlbum
    NBUAssetsGroupTypeEvent         = 1 << 2,       // ALAssetsGroupEvent
    NBUAssetsGroupTypeFaces         = 1 << 3,       // ALAssetsGroupFaces
    NBUAssetsGroupTypeSavedPhotos   = 1 << 4,       // ALAssetsGroupSavedPhotos
    NBUAssetsGroupTypePhotoStream   = 1 << 5,       // ALAssetsGroupPhotoStream
    NBUAssetsGroupTypeAllALGroups   = 0xFFFF,       // All ALAssetsGroups
    
    // Groups from file directories
    NBUAssetsGroupTypeDirectory     = 1 << 16,
    
    NBUAssetsGroupTypeAll           = 0xFFFFFFF    // All groups
};

/// Error constants.
extern NSString * const NBUAssetsErrorDomain;
enum
{
    NBUAssetsFeatureNotAvailableInSystem4   = -101,
    NBUAssetsGroupAlreadyExists             = -102,
    NBUAssetsCouldntRetrieveSomeAssets      = -103
};

/**
 Wrapper to ease acces to the device ALAssetsLibrary media library.
 
 - Asynchronous and fully block-based.
 - Groups and assets are always valid.
 - Groups and images can be retrieved by URL even on iOS4.
 - Read and write access on iOS5+.
 - Create albums, add assets to a given album on iOS5+.
 - Detect permission restrictions on iOS6+.
 */
@interface NBUAssetsLibrary : NSObject

/// @name Shared Assets Library

/// Return a shared NBUAssetsLibrary singleton object.
+ (NBUAssetsLibrary *)sharedLibrary;

/// Set the shared library singleton object.
/// @param library The new shared library. Use nil to release the current object.
+ (void)setSharedLibrary:(NBUAssetsLibrary *)library;


/// 导出集合到系统相册 ,Block第一个参数是否发生错误,第二个参数是否完成,第三个参数当前项索引
+(void) addAll:(NSArray*) array toAlbum:(NSString*)albumName withBlock:(void(^)(NSError *,BOOL,int)) resultBlock;


/// @name Properties

/// Associated ALAssetsLibrary.
@property (strong, nonatomic, readonly)     ALAssetsLibrary * ALAssetsLibrary;

@property (strong, nonatomic, readonly)     PHCachingImageManager * PHCachingImageManager;


/// 注册沙盒中的相册 Register a local directory to automatically create and present a NBUAssetsGroup.
/// @discussion The library will use [NBUAssetsGroup groupForDirectoryURL:name:] to create the group.
/// @param directoryURL The target directory's URL.
/// @param name The optional name to be used for the NBUAssetsGroup.
- (void)registerDirectoryGroupforURL:(NSURL *)directoryURL
                                name:(NSString *)name;

/// @name Access Permissions

/// Whether the user has actively denied access to the library.
@property (nonatomic, readonly)             BOOL userDeniedAccess;

/// Whether parental controls have denied access to the library.
@property (nonatomic, readonly)             BOOL restrictedAccess;

/// @name Asset Groups

/// Retrieve all the groups that are associated to local directories.
/// @discussion Directories' URLs should first be registered using registerDirectoryGroupforURL:name:.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)directoryGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock;

/// The group with all Camera Roll assets (ALAssetsGroupSavedPhotos).
/// @param resultBlock The block to be called asynchronously with the results.
- (void)cameraRollGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// The PhotoStream group with all Camera Roll assets (ALAssetsGroupPhotoStream).
/// @param resultBlock The block to be called asynchronously with the results.
/// @note PhotoStream photos may not be downloaded and there is no public API to force download.
- (void)photoStreamGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// The group with all iTunes synced assets (ALAssetsGroupLibrary).
/// @param resultBlock The block to be called asynchronously with the results.
- (void)photoLibraryGroupWithResultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// Album groups to mimic the device library (Camera Roll, PhotoStream, Photo Library and Albums).
/// @param resultBlock The block to be called asynchronously with the results.
- (void)albumGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock;

/// Retrieve all directory and AssetsLibrary assets groups in that order.
/// @param resultBlock The block to be called asynchronously with the results.
/// @note Does not include photoStreamGroupWithResultBlock results.
- (void)allGroupsWithResultBlock:(NBUAssetsGroupsResultBlock)resultBlock;

/// Retrieve the group of assets that correspons to a given URL.
/// @note Also works in iOS4.
/// @param groupURL A NSURL
/// @param resultBlock The block to be called asynchronously with the results.
- (void)groupForURL:(NSURL *)groupURL
        resultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// Retrieve a group by its name.
/// @param name The name of the group.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)groupWithName:(NSString *)name
          resultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// 创建相册 Create a new group album (iOS5+). Returns an error if name already exists.
/// @param name The desired group name.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)createAlbumGroupWithName:(NSString *)name
                     resultBlock:(NBUAssetsGroupResultBlock)resultBlock;

/// @name Retrieve Assets

/// 加载全部资源(图片+视频) Returns all assets in Camera Roll + Photo library.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)allAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock;

/// 加载全部图片 Returns all image assets in Camera Roll + Photo library.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)allImageAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock;

/// 加载全部视频 Returns all video assets in Camera Roll + Photo library.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)allVideoAssetsWithResultBlock:(NBUAssetsResultBlock)resultBlock;

/// 根据URL加载资源 Retrieve the asset that corresponds to a given URL.
/// @param assetURL A NSURL.
/// @param resultBlock The block to be called asynchronously with the results.
/// @warning Make sure the URL does correspond to an image asset.
- (void)assetForURL:(NSURL *)assetURL
        resultBlock:(NBUAssetResultBlock)resultBlock;

/// 根据URL集合加载资源 Retrieve the assets that corresponds to the given URLs.
/// @param assetURLs An array of asset NSURL's.
/// @param resultBlock The block to be called asynchronously with the results.
/// @warning Make sure the URL does correspond to asset.
-(void)assetsForURLs:(NSArray*)assetURLs
         resultBlock:(NBUAssetsResultBlock)resultBlock;

/// @name Save Assets

/// 保存相片到相册 Save an image to the Camera Roll.
/// @param image 需要保存的图片 The image to save.
/// @param metadata Optional metadata dictionary.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
                   resultBlock:(NBUAssetURLResultBlock)resultBlock;

/// 保存相片到相册 Save an image to the Camera Roll and add to a given group (iOS5+).
/// @param image 需要保存的图片 The image to save.
/// @param metadata Optional metadata dictionary.
/// @param name 相册名称 The target album's name. If an album with that name is not found a
/// new one may be created.
/// @param resultBlock The block to be called asynchronously with the results.
- (void)saveImageToCameraRoll:(UIImage *)image
                     metadata:(NSDictionary *)metadata
      addToAssetsGroupWithName:(NSString *)name
                  resultBlock:(NBUAssetURLResultBlock)resultBlock;

@end

