//
//  TTFIleUtils.m
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//  生成文件名,创建相册,获取所有相册,保存相片,删除相片,

#import "NBUAssetUtils.h"
#import "NBUAsset.h"
#import "UIImage+NBUAdditions.h"
#import "NBULog.h"

#import "RNCryptor.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"

// Document目录路径
static NSString * _documentsDirectory;
static NSString * _password;//密码
@implementation NBUAssetUtils

+(void)initialize{
    // Document目录路径
    _documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    _password = nil;
}

+(void) exitApplication{
    NSArray *arr = [[NSArray alloc]init];
    [arr objectAtIndex:2];
}

+(NSString *)getPassword{
    //NBULogInfo(@"使用的密码是:%@",_password);
    return _password;
}

+(void) setPassword:(NSString *)password{
    //NBULogInfo(@"设置的密码是:%@",password);
    _password = password;
}

+(NSString*) documentsDirectory{
    return _documentsDirectory;
}

#pragma mark 生成文件名
+ (NSString *)getFileName{
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
    // NSString *name =  [NSString stringWithFormat:@"%llu", recordTime];
    // NSString *name = [dateFormatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%llu%@", recordTime, @".jpg"];
}

#pragma mark 创建相册
+(NSString *)createAlbum:(NSString *)albumName{
    BOOL success = NO;
    BOOL isDir = NO;
    BOOL existed = NO;
    NSError * error;
    NSFileManager *manager = [NSFileManager defaultManager];
    
    //创建相册路径
    NSString * amblumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];
    existed = [manager fileExistsAtPath:amblumPath isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        success = [manager createDirectoryAtPath:amblumPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // 创建缩略图文件夹路径
    NSString * thumbpath = [amblumPath stringByAppendingPathComponent: [NBUFileAsset thumbnailDir]];
    existed = [manager fileExistsAtPath:thumbpath isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        success = [manager createDirectoryAtPath:thumbpath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // 创建全屏图片文件夹路径
    NSString * fullScreen = [amblumPath stringByAppendingPathComponent: [NBUFileAsset fullScreenDir]];
    existed = [manager fileExistsAtPath:fullScreen isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        success = [manager createDirectoryAtPath:fullScreen withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return amblumPath;
}

#pragma mark 获取所有相册
+(NSArray *)getAllAlbums{
    NSError * error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentsDirectory error:&error];
    if (error) {
        NBULogInfo(@"Error: %@", error);
        return nil;
    }
    
    NSUInteger count = fileNames.count;
    NSMutableArray * urls = [[NSMutableArray alloc]init];
    
    for (int i = 0; i< count; i++) {
        if ([[[fileNames objectAtIndex:i] pathExtension] isEqualToString:@""] ) {
            [urls addObject: [fileNames objectAtIndex:i]];
        }
    }
    
    return urls;
}

#pragma mark 保存相片到指定相册
+(BOOL)saveImage:(UIImage *) image toAlubm:(NSString *)albumName{
    NSString * fileName = [self getFileName];//文件名
    NSString * albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString * fullName; //临时存储保存的文件全路径名称
    
    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    //[image writeToFile:fullName];
    [self encryImage:image toPath:fullName];
    
    //预览图
    UIImage * fullScreenImage = [image imageDonwsizedToFill:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString * fullScreenDir = [albumPath stringByAppendingPathComponent: [NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName  =[fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    //[fullScreenImage writeToFile:fullName];
    [self encryImage:fullScreenImage toPath:fullName];
    
    //缩略图
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSize]];
    NSString * thumbpath = [albumPath stringByAppendingPathComponent: [NBUFileAsset thumbnailDir]];
    fullName  =[thumbpath stringByAppendingPathComponent:fileName];
    //[thumbImage writeToFile:fullName];
    [self encryImage:thumbImage toPath:fullName];
    
    return YES;
}

#pragma mark 保存视频到相册
+(BOOL)saveVideo:(UIImage *) image toAlubm:(NSString *)albumName  fileName:(NSString*) fileName;{
    NSString * albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    NSString * fullName; //临时存储保存的文件全路径名称
    
    //预览图
    UIImage * fullScreenImage = [image imageDonwsizedToFill:[NBUFileAsset fullScreenSize]];//预览图图片对象
    NSString * fullScreenDir = [albumPath stringByAppendingPathComponent: [NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName  =[fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    //[fullScreenImage writeToFile:fullName];
    [self encryImage:fullScreenImage toPath:fullName];
    
    //缩略图
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUFileAsset thumbnailSize]];
    NSString * thumbpath = [albumPath stringByAppendingPathComponent: [NBUFileAsset thumbnailDir]];
    fullName  =[thumbpath stringByAppendingPathComponent:fileName];
    //[thumbImage writeToFile:fullName];
    [self encryImage:thumbImage toPath:fullName];
    
    return YES;
}

#pragma mark 移动文件
+(BOOL)moveFile:(NBUFileAsset *)assert from:(NSString *)srcAlbumName toAlbum:(NSString *)destAlbumName{
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

/**
 *  旋转照片到正确的方向
 *  可以使用 UIImage+MultiFormat 中扩展的 imageWithOrientationUp方法代替
 */
+ (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark 解密数据到指定相册
+(BOOL)dencryImage:(NBUFileAsset *) image toAlubm:(NSString *)albumName{
    NSString * fileName = [image.fullResolutionImagePath lastPathComponent];//文件名
    NSString * albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//保存到的相册路径
    NSString * fullName; //临时存储保存的文件全路径名称
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDir = NO;
    BOOL existed = NO;
    
    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    //检查文件是否已经存在
    existed = [manager fileExistsAtPath:fullName isDirectory:&isDir];
    if ( existed ==YES || isDir == YES) {//如果已经存在
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
    }else{
        [self dencryImage:image.fullResolutionImagePath toPath:fullName];
    }
    
    //预览图
    NSString * fullScreenDir = [albumPath stringByAppendingPathComponent: [NBUFileAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName  =[fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [self dencryImage:image.fullScreenImagePath toPath:fullName];
    
    //缩略图
    NSString * thumbpath = [albumPath stringByAppendingPathComponent: [NBUFileAsset thumbnailDir]];
    fullName  =[thumbpath stringByAppendingPathComponent:fileName];
    [self dencryImage:image.thumbnailImagePath toPath:fullName];
    
    return YES;
}

#pragma mark 解密数据
/**
 *  解密数据
 *
 *  @param filePath 需要解密的文件
 *  @param path     保存路径
 *
 *  @return 是否成功
 */
+(BOOL)dencryImage:(NSString *) filePath toPath:(NSString *)path{
    NSData *inData = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSData *outData =[RNDecryptor decryptData:inData withSettings:kRNCryptorAES256Settings password:_password error:&error];
    
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
 *
 *  @return 是否成功
 */
+(BOOL)encryImage:(UIImage *) image toPath:(NSString *)path{
    //    NSDate* tmpStartData = [NSDate date];
    //    NBULogInfo(@"执行时间 = %f",  [[NSDate date] timeIntervalSinceDate:tmpStartData]);
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:_password
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
+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath{
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
