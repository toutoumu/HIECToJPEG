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

// Document目录路径
static NSString *_documentsDirectory;

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
    return [NSString stringWithFormat:@"%llu%@", recordTime, @".jpg"];
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
        NBULogInfo(@"Error: %@", error);
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

+ (BOOL)saveImage:(UIImage *)image toAlubm:(NSString *)albumName withFileName:(NSString *)fileName {
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    [self encryptImage:image imageType:0 toPath:fullName withPwd:fileName];

    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFit:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [self encryptImage:fullScreenImage imageType:1 toPath:fullName withPwd:fileName];

    //缩略图,由于thumbnailWithSize需要的尺寸是point值所以传thumbnailSizeNoScale
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSizeNoScale]];
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    [self encryptImage:thumbImage imageType:2 toPath:fullName withPwd:fileName];

    return YES;
}

#pragma mark 保存视频到相册

+ (BOOL)saveVideo:(UIImage *)image toAlubm:(NSString *)albumName fileName:(NSString *)fileName; {
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFit:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [self encryptImage:fullScreenImage imageType:1 toPath:fullName withPwd:fileName];

    //缩略图,由于thumbnailWithSize需要的尺寸是point值所以传thumbnailSizeNoScale
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSizeNoScale]];
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    [self encryptImage:thumbImage imageType:2 toPath:fullName withPwd:fileName];

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
        NBULogInfo(@"Error: %@", error);
        return NO;
    }

    // 全屏图片
    destPath = [assert.fullScreenImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.fullScreenImagePath toPath:destPath error:&error];
    if (error) {
        NBULogInfo(@"Error: %@", error);
        return NO;
    }

    // 缩略图
    destPath = [assert.thumbnailImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.thumbnailImagePath toPath:destPath error:&error];
    if (error) {
        NBULogInfo(@"Error: %@", error);
        return NO;
    }

    return YES;
}


+ (UIImage *)decryImage:(NBUFileAsset *)image {
    if (image == nil || image.URL == nil) {
        return nil;
    }
    BOOL isDir = NO;
    BOOL existed;

    //检查文件是否已经存在
    NSFileManager *manager = [NSFileManager defaultManager];
    existed = [manager fileExistsAtPath:image.fullResolutionImagePath isDirectory:&isDir];
    if (!existed || isDir) {
        NBULogError(@"Error: %@", @"文件不存在");
        return nil;
    }

    NSError *error;
    NSString *pwd = image.fullResolutionImagePath.lastPathComponent;
    NSData *inData = [NSData dataWithContentsOfFile:image.fullResolutionImagePath];
    NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogInfo(@"Error: %@", error);
        return nil;
    }
    return [UIImage imageWithData:outData];
}


#pragma mark 解密数据到指定相册

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
        //[manager moveItemAtPath:image.fullResolutionImagePath toPath:fullName error:&error];
        if (error) {
            NBULogInfo(@"Error: %@", error);
            return NO;
        }
    } else {
        [self decryImage:image.fullResolutionImagePath toPath:fullName withPwd:pwd];
    }

    //预览图
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [self decryImage:image.fullScreenImagePath toPath:fullName withPwd:pwd];

    //缩略图
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    [self decryImage:image.thumbnailImagePath toPath:fullName withPwd:pwd];

    return YES;
}

#pragma mark 解密数据

/**
 *  解密数据
 *
 *  @param filePath 需要解密的文件
 *  @param path     保存路径
 *  @pwd            密码
 *
 *  @return 是否成功
 */
+ (BOOL)decryImage:(NSString *)filePath toPath:(NSString *)path withPwd:(NSString *)pwd {
    NSError *error;
    NSData *inData = [NSData dataWithContentsOfFile:filePath];
    NSData *outData = [RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogInfo(@"Error: %@", error);
        return NO;
    }
    [outData writeToFile:path atomically:true];

    return YES;
}

#pragma mark 加密数据

/**
 *  加密数据
 *
 *  @param image 需要加密的图片
 *  @param type 0:原图 1:全屏图片 2:缩略图
 *  @param path  保存路径
 *  @param pwd   密码
 *
 *  @return 是否成功
 */
+ (BOOL)encryptImage:(UIImage *)image imageType:(NSInteger)type toPath:(NSString *)path withPwd:(NSString *)pwd {
    //    NSDate* tmpStartData = [NSDate date];
    //    NBULogInfo(@"执行时间 = %f",  [[NSDate date] timeIntervalSinceDate:tmpStartData]);
    NSData *data = UIImageJPEGRepresentation(image, (CGFloat) (0.8 - type * 0.3));
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:pwd error:&error];

    if (error != nil) {
        NBULogInfo(@"Error: %@", error);
        return NO;
    }
    [encryptedData writeToFile:path atomically:true];
    return YES;
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
