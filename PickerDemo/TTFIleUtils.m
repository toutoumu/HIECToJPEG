//
//  TTFIleUtils.m
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//  生成文件名,创建相册,获取所有相册,保存相片,删除相片,

#import "TTFIleUtils.h"
#import "NBUAsset.h"
#import "NBUAssetsLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>

// Document目录路径
static NSString * _documentsDirectory;
@implementation TTFIleUtils

+(void)initialize{
    // Document目录路径
    _documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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
    if (!(isDir==YES && existed ==YES)) {
        success = [manager createDirectoryAtPath:amblumPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // 创建缩略图文件夹路径
    NSString * thumbpath = [amblumPath stringByAppendingPathComponent: [NBUAsset thumbnailDir]];
    existed = [manager fileExistsAtPath:thumbpath isDirectory:&isDir];
    if (!(isDir==YES && existed ==YES)) {
        success = [manager createDirectoryAtPath:thumbpath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // 创建全屏图片文件夹路径
    NSString * fullScreen = [amblumPath stringByAppendingPathComponent: [NBUAsset fullScreenDir]];
    existed = [manager fileExistsAtPath:fullScreen isDirectory:&isDir];
    if (!(isDir==YES && existed ==YES)) {
        success = [manager createDirectoryAtPath:fullScreen withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return amblumPath;
}

#pragma mark 获取所有相册
+(NSArray *)getAllAlbums{
    NSError * error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_documentsDirectory error:&error];
    if (error) {
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
    [image writeToFile:fullName];
    
    //预览图
    UIImage * fullScreenImage = [image imageDonwsizedToFill:[NBUAsset fullScreenSize]];//预览图图片对象
    NSString * fullScreenDir = [albumPath stringByAppendingPathComponent: [NBUAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName  =[fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    [fullScreenImage writeToFile:fullName];
    
    //缩略图
    UIImage *thumbImage = [fullScreenImage thumbnailWithSize:[NBUAsset thumbnailSize]];
    NSString * thumbpath = [albumPath stringByAppendingPathComponent: [NBUAsset thumbnailDir]];
    fullName  =[thumbpath stringByAppendingPathComponent:fileName];
    [thumbImage writeToFile:fullName];
    
    return YES;
}

#pragma mark 删除相片
+(BOOL)deletePhoto:(NSString*)fileName toAlbum:(NSString*)albumName{
    //NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
    NSError *error;
    NSString * fullName; //临时存储保存的文件全路径名称
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString * albumPath = [_documentsDirectory stringByAppendingPathComponent:albumName];//相册路径
    
    //原图
    fullName = [albumPath stringByAppendingPathComponent:fileName];// 相册名+文件名
    if ([manager fileExistsAtPath:fullName]) {
        [manager removeItemAtPath:fullName error:&error];
        if (error) {
            NSLog(@"原图删除错误:%@",error);
            return NO;
        }
    }
    
    //预览图
    NSString * fullScreenDir = [albumPath stringByAppendingPathComponent: [NBUAsset fullScreenDir]];//预览图文件夹 相册名+预览图文件夹名称
    fullName  =[fullScreenDir stringByAppendingPathComponent:fileName];//预览图全路径文件名
    if ([manager fileExistsAtPath:fullName]) {
        [manager removeItemAtPath:fullName error:&error];
        if (error) {
            NSLog(@"预览图删除错误:%@",error);
            return NO;
        }
    }
    //缩略图
    NSString * thumbpath = [albumPath stringByAppendingPathComponent: [NBUAsset thumbnailDir]];
    fullName  =[thumbpath stringByAppendingPathComponent:fileName];
    if ([manager fileExistsAtPath:fullName]) {
        [manager removeItemAtPath:fullName error:&error];
        if (error) {
            NSLog(@"缩略图删除错误:%@",error);
            return NO;
        }
    }
    return YES;
    //}];
    //[operation start];
}

#pragma mark 删除相片
+(BOOL)deletePhotoByURL:(NSURL *)url{
    if (!url) {
        return NO;
    }
    BOOL exsist = NO;
    NSError *error;
    NSString * path = [url.path stringByDeletingLastPathComponent];//文件目录
    NSString *fileName = [url.path lastPathComponent];//文件名
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // 原图
    exsist = [manager fileExistsAtPath:url.path];
    if (exsist) {
        [manager removeItemAtPath:url.path error:&error];
        if (error) {
            return NO;
        }
    }
    
    // 缩略图
    NSString * thumbFileName = [[path stringByAppendingPathComponent: [NBUAsset thumbnailDir]] stringByAppendingPathComponent :fileName];
    exsist = [manager fileExistsAtPath:thumbFileName];
    if (exsist) {
        [manager removeItemAtPath:thumbFileName error:&error];
        if (error) {
            return NO;
        }
    }
    
    // 全屏图片
    NSString * fullScreenFileName = [[path stringByAppendingPathComponent: [NBUAsset fullScreenDir]] stringByAppendingPathComponent :fileName];
    exsist = [manager fileExistsAtPath:fullScreenFileName];
    if (exsist) {
        [manager removeItemAtPath:fullScreenFileName error:&error];
        if (error) {
            return NO;
        }
    }
    
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
        return NO;
    }
    
    // 全屏图片
     destPath = [assert.fullScreenImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.fullScreenImagePath toPath:destPath error:&error];
    if (error) {
        return NO;
    }

    // 缩略图
    destPath = [assert.thumbnailImagePath stringByReplacingOccurrencesOfString:srcAlbumName withString:destAlbumName];
    [manager moveItemAtPath:assert.thumbnailImagePath toPath:destPath error:&error];
    if (error) {
        return NO;
    }
    
    return YES;
}


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


















@end
