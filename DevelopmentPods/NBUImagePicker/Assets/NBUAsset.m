//
//  NBUAsset.m
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

#import "NBUAsset.h"
#import "NBUAssetUtils.h"
#import "NBUImagePickerPrivate.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
@import Photos;

// Private classes
/// 8.x以下使用的系统文件访问类接口
@interface NBUALAsset : NBUAsset

- (instancetype)initWithALAsset:(ALAsset *)ALAsset;

@end

/// 8.x以上使用的系统文件访问类接口
@interface NBUPHAsset : NBUAsset <PHPhotoLibraryChangeObserver>

- (instancetype)initWithPHAsset:(PHAsset *)PHAsset;

@end

 /// 沙箱文件使用的,已经被提取出来放到 NBUAsset.h 文件中作为公共类来使用
/*@interface NBUFileAsset : NBUAsset
 
 - (instancetype)initWithFileURL:(NSURL *)fileURL;
 
 /// 缩略图路径
 @property (nonatomic, readonly) NSString * thumbnailImagePath;
 /// 全屏图片路径
 @property (nonatomic, readonly) NSString * fullScreenImagePath;
 /// 原图文件名
 @property (nonatomic, readonly) NSString * fullResolutionImagePath;
 
 @end*/

#pragma mark - 文件访问基类的实现
static CGFloat _scale;
static CGSize _thumbnailSize;
static CGSize _fullScreenSize;
@implementation NBUAsset
/// 初始化基本数据
+ (void)initialize{
    _scale = [UIScreen mainScreen].scale;
    _fullScreenSize = [[UIScreen mainScreen]bounds].size;
    _fullScreenSize = CGSizeMake(_fullScreenSize.width * _scale, _fullScreenSize.height * _scale);
    _thumbnailSize = CGSizeMake(_fullScreenSize.width / 3, _fullScreenSize.width / 3);

}

+(CGFloat) scale{
    return _scale;
}
+(CGSize) thumbnailSize{
    return _thumbnailSize;
}
+(CGSize) fullScreenSize{
    return _fullScreenSize;
}

/// 8.x以下系统使用
+ (NBUAsset *)assetForALAsset:(ALAsset *)ALAsset
{
    return [[NBUALAsset alloc] initWithALAsset:ALAsset];
}

/// 8.x以上系统使用
+ (NBUAsset *)assetForPHAsset:(PHAsset *)PHAsset
{
    return [[NBUPHAsset alloc] initWithPHAsset:PHAsset];
}

/// 沙箱文件系统使用
+ (NBUAsset *)assetForFileURL:(NSURL *)fileURL
{
    return [[NBUFileAsset alloc] initWithFileURL:fileURL];
}

// *** Implement in subclasses if needed ***

- (NSURL *)URL { return nil; }

- (NBUAssetOrientation)orientation { return NBUAssetOrientationUnknown; }

- (BOOL)isEditable { return NO; }

- (CLLocation *)location { return nil; }

- (NSDate *)date { return nil; }

- (NBUAssetType)type { return NBUAssetTypeUnknown; }

- (ALAsset *)ALAsset { return nil; }

- (PHAsset *)PHAsset { return nil; }

- (UIImage *)thumbnailImage { return nil; }

- (UIImage *)fullScreenImage { return nil; }

- (UIImage *)fullResolutionImage { return nil; }

-(void) delete:(void (^)(NSError *, BOOL))reslutBlock{}

@end



#pragma mark - 8.x之前,文件访问系统文件的实现
@implementation NBUALAsset
{
    ALAssetRepresentation * _defaultRepresentation;
}

@synthesize URL = _URL;
@synthesize orientation = _orientation;
@synthesize editable = _editable;
@synthesize location = _location;
@synthesize date = _date;
@synthesize type = _type;
@synthesize ALAsset = _ALAsset;

- (instancetype)initWithALAsset:(ALAsset *)ALAsset
{
    self = [super init];
    if (self)
    {
        if (ALAsset)
        {
            self.ALAsset = ALAsset;
            
            // 注释掉监听 Observe library changes
            /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(libraryChanged:)
                                                         name:ALAssetsLibraryChangedNotification
                                                       object:nil];*/
        }
        else
        {
            self = nil; // Asset is required
        }
    }
    return self;
}

- (void)dealloc
{
    // 注释掉监听,Stop observing
    /*[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ALAssetsLibraryChangedNotification
                                                  object:nil];*/
}

- (void)libraryChanged:(NSNotification *)notification
{
    //    NBULogVerbose(@"Asset thumbnail: %@", _ALAsset.thumbnail);
    //    NBULogVerbose(@"Asset defaultRepresentation: %@", _ALAsset.defaultRepresentation);
    //    NBULogVerbose(@"Asset ALAssetPropertyType: %@", [_ALAsset valueForProperty:ALAssetPropertyType]);
    //    NBULogVerbose(@"Asset ALAssetPropertyOrientation: %@", [_ALAsset valueForProperty:ALAssetPropertyOrientation]);
    //    NBULogVerbose(@"Asset ALAssetPropertyDate: %@", [_ALAsset valueForProperty:ALAssetPropertyDate]);
    //    NBULogVerbose(@"Asset ALAssetPropertyRepresentations: %@", [_ALAsset valueForProperty:ALAssetPropertyRepresentations]);
    
    // Is ALAsset is still valid?
    if (_ALAsset && _ALAsset.defaultRepresentation)
        return;
    
    // Not valid -> Reload ALAsset
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        [[NBUAssetsLibrary sharedLibrary].ALAssetsLibrary assetForURL:_URL
                                                          resultBlock:^(ALAsset * ALAsset)
         {
             if (ALAsset)
             {
                 NBULogVerbose(@"Asset %p had to be reloaded", self);
                 self.ALAsset = ALAsset;
                 // Send notification?
             }
             else
             {
                 NBULogWarn(@"Asset %p couldn't be reloaded. It may no longer exist", self);
                 // Send notification?
             }
         }
                                                         failureBlock:^(NSError * error)
         {
             NBULogError(@"Error while reloading asset %p: %@", self, error);
             // Send notification?
         }];
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; %@>",
            NSStringFromClass([self class]), self, _ALAsset];
}

#pragma mark - Properties
- (void)setALAsset:(ALAsset *)ALAsset
{
    _ALAsset = ALAsset;
    _defaultRepresentation = nil;
    
    // Get URL
    NSArray * URLs = ((NSDictionary *)[_ALAsset valueForProperty:ALAssetPropertyURLs]).allValues;
    if (URLs.count > 0)
    {
        _URL = URLs[0];
        if (URLs.count != 1)
        {
            NBULogInfo(@"Asset %@ doesn't have a single URL, we chosed one: %@ -> %@",
                       self, [_ALAsset valueForProperty:ALAssetPropertyURLs], _URL);
        }
    }
    else
    {
        NBULogError(@"Can't find a URL for the asset %@", ALAsset);
    }
}

- (NBUAssetOrientation)orientation
{
    if (_orientation == NBUAssetOrientationUnknown)
    {
        ALAssetOrientation orientation = self.defaultRepresentation.orientation;
        
        // Portrait: ALAssetOrientationLeft, Right, LeftMirrored, RightMirrored
        if (orientation == ALAssetOrientationLeft ||
            orientation == ALAssetOrientationRight ||
            orientation == ALAssetOrientationLeftMirrored ||
            orientation == ALAssetOrientationRightMirrored)
        {
            _orientation = NBUAssetOrientationPortrait;
        }
        // Landscape: ALAssetOrientationUp, Down, UpMirrored, DownMirrored
        else
        {
            _orientation = NBUAssetOrientationLandscape;
        }
    }
    return _orientation;
}

- (BOOL)isEditable
{
    if (!_editable)
    {
        _editable = _ALAsset.editable;
    }
    return _editable;
}

- (NBUAssetType)type
{
    if (!_type)
    {
        NSString * typeString = [_ALAsset valueForProperty:ALAssetPropertyType];
        if ([typeString isEqualToString:ALAssetTypePhoto])
        {
            _type = NBUAssetTypeImage;
        }
        else if ([typeString isEqualToString:ALAssetTypeVideo])
        {
            _type = NBUAssetTypeVideo;
        }
    }
    return _type;
}

- (NSDate *)date
{
    if (!_date)
    {
        _date = [_ALAsset valueForProperty:ALAssetPropertyDate];
    }
    return _date;
}

- (CLLocation *)location
{
    if (!_location)
    {
        _location = [_ALAsset valueForProperty:ALAssetPropertyLocation];
    }
    return _location;
}

#pragma mark - Images

- (ALAssetRepresentation *)defaultRepresentation
{
    if (!_defaultRepresentation)
    {
        _defaultRepresentation = _ALAsset.defaultRepresentation;
    }
    return _defaultRepresentation;
}

- (UIImage *)thumbnailImage
{
    return [UIImage imageWithCGImage:_ALAsset.thumbnail];
}

- (UIImage *)fullScreenImage
{
    // "In iOS 5 and later, this method returns a fully cropped, rotated, and adjusted image—exactly as a user would see in Photos or in the image picker."
    UIImage * image = [UIImage imageWithCGImage:self.defaultRepresentation.fullScreenImage
                                          scale:self.defaultRepresentation.scale
                                    orientation:UIImageOrientationUp];
    NBULogVerbose(@"fullScreenImage with size: %@ orientation %@",
                  NSStringFromCGSize(image.size), @(image.imageOrientation));
    return image;
}

- (UIImage *)fullResolutionImage
{
    // "This method returns the biggest, best representation available, unadjusted in any way."
    UIImage * image = [UIImage imageWithCGImage:self.defaultRepresentation.fullResolutionImage
                                          scale:self.defaultRepresentation.scale
                                    orientation:(UIImageOrientation)self.defaultRepresentation.orientation];
    NBULogVerbose(@"fullResolutionImage with size: %@ orientation %@",
                  NSStringFromCGSize(image.size), @(image.imageOrientation));
    return image;
}

-(void) delete:(void (^)(NSError *, BOOL))reslutBlock{
    if (!_ALAsset.isEditable) {
        return ;
    }
    //在这里imageData 和 metaData设为nil，就可以将相册中的照片删除
    [_ALAsset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        NBULogInfo(@"asset url(%@) should be delete . Error:%@ ", assetURL, error);
        if (reslutBlock) {
            if (error) {
                reslutBlock(error, NO);
            }else{
                reslutBlock(error, YES);
            }
        }
    }];
}

@end




#pragma mark - 沙箱文件访问的实现
static NSString * _thumbnailDir;
static NSString * _fullScreenDir;

@implementation NBUFileAsset
{
    // 相册所在路径
    NSString *albumPath;
    // 缩略图路径
    //NSString *thumbnailImagePath;
    // 全屏图片路径
    //NSString * fullScreenImagePath;
    // 文件名
    NSString * fileName;
    
    NBUAssetType _type;
}

@synthesize URL = _URL;
//@synthesize type = _type;
//@synthesize thumbnailImage = _thumbnailImage;
//@synthesize fullScreenImage = _fullScreenImage;
@synthesize thumbnailImagePath = _thumbnailImagePath;
@synthesize fullScreenImagePath = _fullScreenImagePath;

+(void)initialize{
    _thumbnailDir = @"thumbnail";
    _fullScreenDir = @"fullscreen";
}


+(NSString *)thumbnailDir{
    return _thumbnailDir;
}
+(NSString *)fullScreenDir{
    return _fullScreenDir;
}

- (BOOL)isEditable { return YES; }

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self)
    {
        _URL = fileURL;
        _type = NBUAssetTypeImage;
        // 文件名
        fileName = fileURL.path.lastPathComponent;
        if ([fileName hasSuffix:@"mov"]) {
            _type = NBUAssetTypeVideo;
        }
        // 相册路径
        albumPath = [fileURL.path stringByDeletingLastPathComponent];
        // 缩略图路径
        //thumbnailImagePath = [[albumPath stringByAppendingPathComponent:_thumbnailDir] stringByAppendingPathComponent:fileName];
        // 全屏图片路径
        //fullScreenImagePath =[[albumPath stringByAppendingPathComponent:_fullScreenDir] stringByAppendingPathComponent:fileName];
    }
    return self;
}

- (NBUAssetType)type{
    return _type;
    //return NBUAssetTypeImage;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; %@>",
            NSStringFromClass([self class]), self, fileName];
}

///// UIImage不能缓存起来,如果缓存起来会导致内存消耗过大,应该是使用完成之后即刻释放
-(UIImage *)thumbnailImage{
    return [UIImage imageWithContentsOfFile:self.thumbnailImagePath];
    /*UIImage *iamge;
     // 如果缩略图不存在
     if (![[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailImagePath]) {
     // 这里从原始尺寸图片切图
     iamge = [self.fullResolutionImage thumbnailWithSize:_thumbnailSize];
     [iamge writeToFile:self.thumbnailImagePath];
     }else{
     iamge = [UIImage imageWithContentsOfFile:self.thumbnailImagePath];
     }
     return iamge;*/
}

///// UIImage不能缓存起来,如果缓存起来会导致内存消耗过大,应该是使用完成之后即刻释放
- (UIImage *)fullScreenImage
{
    return [UIImage imageWithContentsOfFile:self.fullScreenImagePath];
    /*UIImage *iamge;
     // 如果全屏图不存在
     if (![[NSFileManager defaultManager] fileExistsAtPath:self.fullScreenImagePath]) {
     // 生成全屏图片
     iamge = [self.fullResolutionImage imageDonwsizedToFill:_fullScreenSize];
     [iamge writeToFile:self.fullScreenImagePath];
     }else{
     iamge = [UIImage imageWithContentsOfFile:self.fullScreenImagePath];
     }
     return iamge;*/
}


- (UIImage *)fullResolutionImage
{
    return [UIImage imageWithContentsOfFile:_URL.path];
}

-(NSString *)thumbnailImagePath{
    if(_thumbnailImagePath == nil){
        // 缩略图路径
        _thumbnailImagePath = [[albumPath stringByAppendingPathComponent:_thumbnailDir] stringByAppendingPathComponent:fileName];
    }
    return _thumbnailImagePath;
}

-(NSString *)fullScreenImagePath{
    if (_fullScreenImagePath == nil) {
        // 全屏图片路径
        _fullScreenImagePath =[[albumPath stringByAppendingPathComponent:_fullScreenDir] stringByAppendingPathComponent:fileName];
    }
    return _fullScreenImagePath;
}

-(NSString *)fullResolutionImagePath{
    return _URL.path;
}

+(BOOL) deleteAll:(NSArray *)array{
    BOOL exsist = NO;
    BOOL result = YES;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];

    for (NBUFileAsset *file in array) {
        if (file.URL ==nil || file.URL.path ==nil) {
            return NO;
        }
        // 原图
        exsist = [manager fileExistsAtPath:file.URL.path];
        if (exsist) {
            [manager removeItemAtPath:file.URL.path error:&error];
            if (error != nil) {
                result = NO;
                break;
            }
        }
        
        // 缩略图
        exsist = [manager fileExistsAtPath:file.thumbnailImagePath];
        if (exsist) {
            [manager removeItemAtPath:file.URL.path error:&error];
            if (error != nil) {
                result = NO;
                break;
            }
        }

        // 全屏图片
        exsist = [manager fileExistsAtPath:file.fullScreenImagePath];
        if (exsist) {
            [manager removeItemAtPath:file.URL.path error:&error];
            if (error != nil) {
                result = NO;
                break;
            }
        }

    }
    if (error!=nil) {
        NBULogInfo(@"Error: %@", error);
    }
    return result;
}

-(void) delete:(void (^)(NSError *, BOOL))reslutBlock{
    if (_URL == nil || _URL.path == nil) {
        if (reslutBlock) {
            NSError *error = [[NSError alloc] initWithDomain:@"出错了URL不能为空" code:12 userInfo:nil];
            reslutBlock(error, NO);
        }
        return ;
    }
    BOOL exsist = NO;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // 原图
    exsist = [manager fileExistsAtPath:_URL.path];
    if (exsist) {
        [manager removeItemAtPath:_URL.path error:&error];
        if (error) {
            if (reslutBlock) {
                reslutBlock(error, NO);
            }
            return ;
        }
    }
    
    // 缩略图
    exsist = [manager fileExistsAtPath:self.thumbnailImagePath];
    if (exsist) {
        [manager removeItemAtPath:self.thumbnailImagePath error:&error];
        if (error) {
            if (reslutBlock) {
                reslutBlock(error, NO);
            }
            return ;
        }
    }
    
    // 全屏图片
    exsist = [manager fileExistsAtPath:self.fullScreenImagePath];
    if (exsist) {
        [manager removeItemAtPath:self.fullScreenImagePath error:&error];
        if (error) {
            if (reslutBlock) {
                reslutBlock(error, NO);
            }
            return ;
        }else{
            if (reslutBlock) {
                reslutBlock(error, YES);
            }
        }
    }
}
@end




#pragma mark - 8.x以上系统文件访问系统文件的实现
@implementation NBUPHAsset
{
    // ALAssetRepresentation * _defaultRepresentation;
    /*
     PHImageFileOrientationKey = 0;
     PHImageFileSandboxExtensionTokenKey = "c70cde35ce8d81da8a84b59abf3d587f91cfbe9e;00000000;00000000;000000000000001a;com.apple.app-              sandbox.read;00000001;01000004;0000000002c5d026;/users/liubin/library/developer/coresimulator/devices/b3e59db2-b1d6-4e18-bf26-166beb28b466/data/media/dcim/100apple/img_0002.jpg";
     PHImageFileURLKey = "file:///Users/liubin/Library/Developer/CoreSimulator/Devices/B3E59DB2-B1D6-4E18-BF26-166BEB28B466/data/Media/DCIM/100APPLE/IMG_0002.JPG";
     PHImageFileUTIKey = "public.jpeg";
     PHImageResultDeliveredImageFormatKey = 9999;
     PHImageResultIsDegradedKey = 0;
     PHImageResultIsInCloudKey = 0;
     PHImageResultIsPlaceholderKey = 0;
     PHImageResultWantedImageFormatKey = 9999;
     */
    NSDictionary *_phAssetInfo;
}

@synthesize URL = _URL;
@synthesize orientation = _orientation;
@synthesize editable = _editable;
@synthesize location = _location;
@synthesize date = _date;
@synthesize type = _type;
@synthesize PHAsset = _PHAsset;

- (instancetype)initWithPHAsset:(PHAsset *)PHAsset
{
    self = [super init];
    if (self)
    {
        if (PHAsset)
        {
            self.PHAsset = PHAsset;
            // Observe library changes
            //[[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
        else
        {
            self = nil; // Asset is required
        }
    }
    return self;
}

- (void)dealloc
{
    // Stop observing
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}
/// 与8.x之前系统的AlAssets类的libraryChanged对应
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (!_PHAsset)
        return;
    
    // Not valid -> Reload ALAsset
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // Check if there are changes to the assets we are showing.
        PHObjectChangeDetails *objChangeDetails = [changeInstance changeDetailsForObject:_PHAsset];
        if (objChangeDetails == nil) {
            return;
        }
        if (objChangeDetails.objectWasDeleted) {
            NBULogWarn(@"Asset %p couldn't be reloaded. It may no longer exist", self);
            _PHAsset = nil;
            return;
        }
        if (objChangeDetails .objectAfterChanges) {
            NBULogVerbose(@"Asset %p had to be reloaded", self);
            _PHAsset = objChangeDetails.objectAfterChanges;
        }
    });
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; %@>",
            NSStringFromClass([self class]), self, _PHAsset];
}

#pragma mark- Properties
- (void)setPHAsset:(PHAsset *)PHAsset
{
    _PHAsset = PHAsset;
    if (!_phAssetInfo) {
        // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
        [self requestPhAssetInfo];
    }
    // 从 PhAssetInfo 中获取 UIImageOrientation 对应的字段
    _URL = (NSURL*)_phAssetInfo[@"PHImageFileURLKey"];
}

- (NBUAssetOrientation)orientation
{
    if (_orientation == NBUAssetOrientationUnknown)
    {
        if (!_phAssetInfo) {
            // PHAsset 的 UIImageOrientation 需要调用过 requestImageDataForAsset 才能获取
            [self requestPhAssetInfo];
        }
        // 从 PhAssetInfo 中获取 UIImageOrientation 对应的字段
        //        UIImageOrientation orientation = (UIImageOrientation)[_phAssetInfo[@"orientation"] integerValue];
        UIImageOrientation orientation = (UIImageOrientation)[_phAssetInfo[@"PHImageFileOrientationKey"] integerValue];
        
        // Portrait: ALAssetOrientationLeft, Right, LeftMirrored, RightMirrored
        if (orientation == UIImageOrientationLeft ||
            orientation == UIImageOrientationRight ||
            orientation == UIImageOrientationLeftMirrored ||
            orientation == UIImageOrientationRightMirrored)
        {
            _orientation = NBUAssetOrientationPortrait;
        }
        // Landscape: ALAssetOrientationUp, Down, UpMirrored, DownMirrored
        else
        {
            _orientation = NBUAssetOrientationLandscape;
        }
    }
    return _orientation;
}


-(void) requestPhAssetInfo{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:_PHAsset
                                                      options:options
                                                resultHandler:
     ^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
         _phAssetInfo = info;
     }];
}

- (BOOL)isEditable
{
    return YES;
    /*
     if (!_editable)
     {
     _editable = _PHAsset.editable;
     }
     return _editable;
     */
}

- (NBUAssetType)type
{
    if (!_type)
    {
        PHAssetMediaType typeString = _PHAsset.mediaType;
        switch (typeString) {
            case PHAssetMediaTypeUnknown: {
                _type = NBUAssetTypeUnknown;
                break;
            }
            case PHAssetMediaTypeImage: {
                _type = NBUAssetTypeImage;
                break;
            }
            case PHAssetMediaTypeVideo: {
                _type = NBUAssetTypeVideo;
                break;
            }
            case PHAssetMediaTypeAudio: {
                _type = NBUAssetTypeUnknown;
                break;
            }
        }
    }
    return _type;
}

- (NSDate *)date
{
    if (!_date)
    {
        _date = [_PHAsset creationDate];
    }
    return _date;
}

- (CLLocation *)location
{
    if (!_location)
    {
        _location = [_PHAsset location];
    }
    return _location;
}

#pragma mark - Images
- (UIImage *)thumbnailImage
{
    __block UIImage *resultImage;
    PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
    phImageRequestOptions.synchronous = YES;
    phImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    // 在PHImageManager中，targetSize等size都是使用px作为单位，因此需要对targetSize中对传入的Size进行处理，宽高各自乘以ScreenScale，从而得到正确的图片
    PHCachingImageManager *PHCachingImageManager = [NBUAssetsLibrary sharedLibrary].PHCachingImageManager;
    [PHCachingImageManager requestImageForAsset:_PHAsset
                                     targetSize:_thumbnailSize
                                    contentMode:PHImageContentModeAspectFill
                                        options:phImageRequestOptions
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      resultImage = result;
                                  }];
    return resultImage;
}

- (UIImage *)fullScreenImage
{
    __block UIImage *resultImage;
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.synchronous = YES;
    PHCachingImageManager *PHCachingImageManager = [NBUAssetsLibrary sharedLibrary].PHCachingImageManager;
    [PHCachingImageManager requestImageForAsset:_PHAsset
                                     targetSize:CGSizeMake(_fullScreenSize.width*_scale, _fullScreenSize.height*_scale)
                                    contentMode:PHImageContentModeAspectFill
                                        options:imageRequestOptions
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      resultImage = result;
                                  }];
    return resultImage;
}

- (UIImage *)fullResolutionImage
{
    __block UIImage *resultImage;
    PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
    phImageRequestOptions.synchronous = YES;
    PHCachingImageManager *PHCachingImageManager = [NBUAssetsLibrary sharedLibrary].PHCachingImageManager;
    [PHCachingImageManager requestImageForAsset:_PHAsset
                                     targetSize:PHImageManagerMaximumSize
                                    contentMode:PHImageContentModeDefault
                                        options:phImageRequestOptions
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      resultImage = result;
                                  }];
    return resultImage;
}

-(void)delete:(void (^)(NSError *, BOOL))reslutBlock{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:@[_PHAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (reslutBlock) {
            if (error) {
                reslutBlock(error, NO);
                NBULogInfo(@"Error: %@", error);
            }else{
                reslutBlock(error, YES);
            }
        }
    }];
}



@end // 8.x以上系统使用的

