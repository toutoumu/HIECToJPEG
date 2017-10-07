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
static NSString *_password;//密码
@implementation NBUAssetUtils

+ (void)initialize {
    // Document目录路径
    _documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    _password = nil;
}

+ (void)exitApplication {
    NSArray *arr = [[NSArray alloc] init];
    [arr objectAtIndex:2];
}

+ (NSString *)getPassword {
    //NBULogInfo(@"使用的密码是:%@",_password);
    return _password;
}

+ (void)setPassword:(NSString *)password {
    //NBULogInfo(@"设置的密码是:%@",password);
    _password = password;
}

+ (NSString *)documentsDirectory {
    return _documentsDirectory;
}

#pragma mark 生成文件名

+ (NSString *)getFileName {
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970] * 1000;
    // NSString *name =  [NSString stringWithFormat:@"%llu", recordTime];
    // NSString *name = [dateFormatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%llu%@", recordTime, @".jpg"];
}

#pragma mark 创建相册

+ (NSString *)createAlbum:(NSString *)albumName {
    BOOL success = NO;
    BOOL isDir = NO;
    BOOL existed = NO;
    NSError *error;
    NSFileManager *manager = [NSFileManager defaultManager];

    //创建相册路径
    NSString *amblumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];
    existed = [manager fileExistsAtPath:amblumPath isDirectory:&isDir];
    if (!(isDir && existed)) {
        success = [manager createDirectoryAtPath:amblumPath withIntermediateDirectories:YES attributes:nil error:&error];
    }

    // 创建缩略图文件夹路径
    NSString *thumbPath = [amblumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    existed = [manager fileExistsAtPath:thumbPath isDirectory:&isDir];
    if (!(isDir && existed)) {
        success = [manager createDirectoryAtPath:thumbPath withIntermediateDirectories:YES attributes:nil error:&error];
    }

    // 创建全屏图片文件夹路径
    NSString *fullScreen = [amblumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];
    existed = [manager fileExistsAtPath:fullScreen isDirectory:&isDir];
    if (!(isDir && existed)) {
        success = [manager createDirectoryAtPath:fullScreen withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return amblumPath;
}

#pragma mark 获取所有相册

+ (NSArray *)getAllAlbums {
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentsDirectory error:&error];
    if (error) {
        NBULogInfo(@"Error: %@", error);
        return nil;
    }

    NSUInteger count = fileNames.count;
    NSMutableArray *urls = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i < count; i++) {
        if ([[fileNames[i] pathExtension] isEqualToString:@""]) {
            [urls addObject:fileNames[i]];
        }
    }

    return urls;
}

#pragma mark 保存相片到指定相册

+ (BOOL)saveImage:(UIImage *)image toAlubm:(NSString *)albumName {
    NSString *fileName = [self getFileName];//文件名
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    //[image writeToFile:fullName];
    [self encryImage:image toPath:fullName withPwd:fileName];

    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFill:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    //[fullScreenImage writeToFile:fullName];
    [self encryImage:fullScreenImage toPath:fullName withPwd:fileName];

    //缩略图
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSize]];
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    //[thumbImage writeToFile:fullName];
    [self encryImage:thumbImage toPath:fullName withPwd:fileName];

    return YES;
}

#pragma mark 保存视频到相册

+ (BOOL)saveVideo:(UIImage *)image toAlubm:(NSString *)albumName fileName:(NSString *)fileName; {
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    //预览图
    UIImage *fullScreenImage = [image imageDonwsizedToFill:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    //[fullScreenImage writeToFile:fullName];
    [self encryImage:fullScreenImage toPath:fullName withPwd:fileName];

    //缩略图
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSize]];
    NSString *thumbpath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbpath stringByAppendingPathComponent:fileName];
    //[thumbImage writeToFile:fullName];
    [self encryImage:thumbImage toPath:fullName withPwd:fileName];

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


#pragma mark 解密数据到指定相册

+ (BOOL)dencryImage:(NBUFileAsset *)image toAlubm:(NSString *)albumName withPwd:(NSString *)pwd {
    NSString *fileName = [image.fullResolutionImagePath lastPathComponent];//文件名
    NSString *albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//保存到的相册路径
    NSString *fullName; //临时存储保存的文件全路径名称

    NSFileManager *manager = [NSFileManager defaultManager];

    BOOL isDir = NO;
    BOOL existed = NO;

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
        [self dencryImage:image.fullResolutionImagePath toPath:fullName withPwd:pwd];
    }

    //预览图
    NSString *fullScreenDir = [albumPath stringByAppendingPathComponent:[NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName = [fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [self dencryImage:image.fullScreenImagePath toPath:fullName withPwd:pwd];

    //缩略图
    NSString *thumbPath = [albumPath stringByAppendingPathComponent:[NBUFileAsset thumbnailDir]];
    fullName = [thumbPath stringByAppendingPathComponent:fileName];
    [self dencryImage:image.thumbnailImagePath toPath:fullName withPwd:pwd];

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
+ (BOOL)dencryImage:(NSString *)filePath toPath:(NSString *)path withPwd:(NSString *)pwd {
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
 *  @param path  保存路径
 *  @param pwd   密码
 *
 *  @return 是否成功
 */
+ (BOOL)encryImage:(UIImage *)image toPath:(NSString *)path withPwd:(NSString *)pwd {
    //    NSDate* tmpStartData = [NSDate date];
    //    NBULogInfo(@"执行时间 = %f",  [[NSDate date] timeIntervalSinceDate:tmpStartData]);
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:pwd
                                               error:&error];

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
