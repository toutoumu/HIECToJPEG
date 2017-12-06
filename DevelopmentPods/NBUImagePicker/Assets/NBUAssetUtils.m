//
//  TTFIleUtils.m
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//  生成文件名,创建相册,获取所有相册,保存相片,删除相片,

#import "NBUAsset.h"
#import "NBUAssetUtils.h"

#import "RNCryptor.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import <VideoToolbox/VideoToolbox.h>

// Document目录路径
static NSString *_documentsDirectory;

/**
 *
 * HEIF(HEIC) 格式转 JPEG 格式
 * @param imageData
 * @return
 */
NSData *HEIFtoJPEG(NSData *imageData) {
    /*
     // 这种方式是否可行未测试
     if (@available(iOS 11.0, *)) {
        UIImage *image = [UIImage imageWithData:imageData];
        return UIImageJPEGRepresentation(image, 1.0f);
     }
     */
    if (@available(iOS 11.0, *)) {
        CIImage *ciImage = [CIImage imageWithData:imageData];
        CIContext *context = [CIContext context];
        return [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
    }
    return nil;
}

/**
 * 获取图片数据中的缩略图
 * @param data
 * @return
 */
UIImage *thumbImage(NSData *data) {
    //BOOL hardwareDecodeSupported = VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    //CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);//原图

    // 缩略图选项(如果有则获取)
    NSDictionary *options = @{(NSString *) kCGImageSourceCreateThumbnailFromImageIfAbsent: @NO,
            (NSString *) kCGImageSourceThumbnailMaxPixelSize: @320};

    CGImageRef thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) options);
    UIImage *shotImage = [[UIImage alloc] initWithCGImage:thumb];
    return shotImage;
}

/**
 * JPEG 格式转 HEIF(HEIC) 格式
 * @param image
 * @param quality 0.8
 * @return nil 创建失败，说明设备不支持 HEIF 写入
 * @discussion 关于哪些设备支持HEIF(HEIC)格式请参考 https://juejin.im/post/59ddc13ff265da432319f438#heading-3
 */
NSData *UIImageHEICRepresentation(UIImage *const image, const CGFloat quality) {
    NSData *imageData = nil;
    if (@available(iOS 11.0, *) && image) {
        NSMutableData *destinationData = [NSMutableData new];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) destinationData, (__bridge CFStringRef) AVFileTypeHEIC, 1, NULL);
        if (destination) {
            NSDictionary *options = @{(__bridge NSString *) kCGImageDestinationLossyCompressionQuality: @(quality)};
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef) options);
            CGImageDestinationFinalize(destination);
            imageData = destinationData;
            CFRelease(destination);
        }
    }
    return imageData;
}

@implementation NBUAssetUtils

+ (void)initialize {
    // Document目录路径
    _documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

+ (void)exitApplication {
    NSArray *arr = [[NSArray alloc] init];
    arr[2];
}

+ (NSString *)documentsDirectory {
    return _documentsDirectory;
}

#pragma mark 生成文件名

+ (NSString *)createFileName {
    UInt64 recordTime = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    if (@available(iOS 11.0, *)) {
        return [NSString stringWithFormat:@"%llu%@", recordTime, @".HEIC"];
    } else {
        return [NSString stringWithFormat:@"%llu%@", recordTime, @".jpg"];
    }
}

#pragma mark 创建相册

+ (NSString *)createAlbum:(NSString *)albumName {
    BOOL isDir = NO;
    BOOL existed;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];

    //创建相册路径
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];
    existed = [manager fileExistsAtPath:albumPath isDirectory:&isDir];
    if (!(isDir && existed)) {
        [manager createDirectoryAtPath:albumPath withIntermediateDirectories:YES attributes:nil error:&error];
    }

    // 创建缩略图文件夹路径
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    existed = [manager fileExistsAtPath:thumbPath isDirectory:&isDir];
    if (!(isDir && existed)) {
        [manager createDirectoryAtPath:thumbPath withIntermediateDirectories:YES attributes:nil error:&error];
    }

    // 创建全屏图片文件夹路径
    NSString *fullScreen = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];
    existed = [manager fileExistsAtPath:fullScreen isDirectory:&isDir];
    if (!(isDir && existed)) {
        [manager createDirectoryAtPath:fullScreen withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return albumPath;
}

#pragma mark 获取所有相册(相册名称列表)

+ (NSArray *)getAllAlbums {
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentsDirectory error:&error];
    if (error) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return nil;
    }

    NSUInteger count = fileNames.count;
    NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++) {
        if ([[fileNames[i] pathExtension] isEqualToString:@""]) {
            [urls addObject:fileNames[i]];
        }
    }

    return urls;
}

#pragma mark 保存相片到指定相册

+ (BOOL)saveImage:(UIImage *)image imageData:(NSData *)data toAlubm:(NSString *)albumName withFileName:(NSString *)fileName {
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称
    BOOL success;//是否成功

    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    success = [self encryptImage:image imageData:data imageType:0 toPath:fullName withPwd:fileName];
    if (!success) {return success;}

    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFit:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    success = [self encryptImage:fullScreenImage imageData:nil imageType:1 toPath:fullName withPwd:fileName];
    if (!success) {return success;}

    //缩略图,由于thumbnailWithSize需要的尺寸是point值所以传thumbnailSizeNoScale
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSizeNoScale]];
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    success = [self encryptImage:thumbImage imageData:nil imageType:2 toPath:fullName withPwd:fileName];
    if (!success) {return success;}
    return YES;
}

#pragma mark 保存视频到相册

+ (BOOL)saveVideo:(UIImage *)image toAlubm:(NSString *)albumName fileName:(NSString *)fileName; {
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称
    BOOL success;
    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFit:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    success = [self encryptImage:fullScreenImage imageData:nil imageType:1 toPath:fullName withPwd:fileName];
    if (!success) {return success;}

    //缩略图,由于thumbnailWithSize需要的尺寸是point值所以传thumbnailSizeNoScale
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSizeNoScale]];
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    success = [self encryptImage:thumbImage imageData:nil imageType:2 toPath:fullName withPwd:fileName];
    if (!success) {return success;}

    return YES;
}

#pragma mark 移动文件

+ (BOOL)moveFile:(NBUFileAsset *)assert from:(NSString *)srcAlbumName toAlbum:(NSString *)destAlbumName {
    if (!assert) {
        return NO;
    }
    NSError *error;

    NSFileManager *manager = [NSFileManager defaultManager];
    // 原图
    NSString *destPath = [assert.fullResolutionImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.fullResolutionImagePath toPath:destPath error:&error];
    if (error) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return NO;
    }

    // 全屏图片
    destPath = [assert.fullScreenImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.fullScreenImagePath toPath:destPath error:&error];
    if (error) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return NO;
    }

    // 缩略图
    destPath = [assert.thumbnailImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.thumbnailImagePath toPath:destPath error:&error];
    if (error) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return NO;
    }

    return YES;
}


+ (UIImage *)decryImage:(NBUFileAsset *)image {
    if (image == nil || image.URL == nil) {
        return nil;
    }
    return [self decryImageWithPath:image.fullResolutionImagePath];
}

+ (UIImage *)decryImageWithPath:(NSString *)path {
    BOOL isDir = NO;
    BOOL existed;

    //检查文件是否已经存在
    NSFileManager *manager = [NSFileManager defaultManager];
    existed = [manager fileExistsAtPath:path isDirectory:&isDir];
    if (!existed || isDir) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, @"文件不存在");
        return nil;
    }

    NSError *error;
    NSString *pwd = path.lastPathComponent;
    NSData *inData = [NSData dataWithContentsOfFile:path];
    NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return nil;
    }
    return [UIImage imageWithData:outData];
}


#pragma mark 解密数据到指定相册

/**
 * 解密数据到指定相册
 *
 * @param image
 * @param albumName 相册名称 eg:picture
 * @param pwd
 * @return
 */
+ (BOOL)decryImage:(NBUFileAsset *)image toAlubm:(NSString *)albumName withPwd:(NSString *)pwd {
    NSString *fileName = [image.fullResolutionImagePath lastPathComponent];//文件名
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//保存到的相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    NSFileManager *manager = [NSFileManager defaultManager];

    BOOL isDir = NO;
    BOOL existed;

    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    //检查文件是否已经存在
    existed = [manager fileExistsAtPath:fullName isDirectory:&isDir];
    if (existed || isDir) {//如果已经存在
        return YES;
    }
    // 视频文件没有加密,直接将文件复制过去
    if (image.type == NBUAssetTypeVideo) {
        NSError *error;
        [manager copyItemAtPath:image.fullResolutionImagePath toPath:fullName error:&error];
        if (error) {
            NBULogError(@"Error: %@ %@", THIS_METHOD, error);
            return NO;
        }
    } else {
        [self decryImage:image.fullResolutionImagePath toPath:fullName withPwd:pwd];
    }

    //预览图
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    if (![self decryImage:image.fullScreenImagePath toPath:fullName withPwd:pwd]) {
        return NO;
    }

    //缩略图
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    return [self decryImage:image.thumbnailImagePath toPath:fullName withPwd:pwd];
}

#pragma mark 解密数据

/**
 *  解密数据
 *
 *  @param filePath 需要解密的文件路径 /data/images/xxx.jpg
 *  @param path     保存路径 /data/images/xxx.jpg
 *  @pwd            密码
 *
 *  @return 是否成功
 */
+ (BOOL)decryImage:(NSString *)filePath toPath:(NSString *)path withPwd:(NSString *)pwd {
    NSError *error;
    NSData *inData = [NSData dataWithContentsOfFile:filePath];
    NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return NO;
    }
    [outData writeToFile:path atomically:true];
    return YES;
}

#pragma mark 加密图片数据

/**
 *  加密图片数据(如果兼容 HEIF(HEIC) 格式,则使用 HEIF(HEIC) 格式)
 *
 *  @param image 需要加密的图片
 *  @param data 图片数据 HEIF(HEIC)格式
 *  @param type 0:原图 1:全屏图片 2:缩略图
 *  @param path  保存路径 /data/images/xxx.jpg
 *  @param pwd   密码
 *
 *  @return 是否成功
 */
+ (BOOL)encryptImage:(UIImage *)image imageData:(NSData *)data imageType:(NSInteger)type toPath:(NSString *)path withPwd:(NSString *)pwd {
    //    NSDate* tmpStartData = [NSDate date];
    //    NBULogInfo(@"执行时间 = %f",  [[NSDate date] timeIntervalSinceDate:tmpStartData]);

    if (@available(iOS 11.0, *)) {
        if (data == nil || data.length == 0) {
            data = UIImageHEICRepresentation(image, (CGFloat) (0.8 - type * 0.3));
            if (data == nil || data.length == 0) {// 如果设备不支持 HEIF(HEIC) 格式
                data = UIImageJPEGRepresentation(image, (CGFloat) (0.8 - type * 0.3));
            }
        }
    } else {//不支持HEIF(HEIC),编码为JPEG
        data = UIImageJPEGRepresentation(image, (CGFloat) (0.8 - type * 0.3));
    }

    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogError(@"Error: %@ %@", THIS_METHOD, error);
        return NO;
    }

    return [encryptedData writeToFile:path atomically:true];
}


/**
 *  获取视频的缩略图方法
 *
 *  @param filePath 视频的本地路径
 *
 *  @return 视频截图
 */
+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath {
    //视频路径URL
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;

    CMTime actualTime;
    NSError *error = nil;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return shotImage;
}

@end
