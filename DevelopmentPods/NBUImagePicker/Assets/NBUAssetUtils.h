//
//  TTFIleUtils.h
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//

#import "NBUImagePicker.h"
#import <Foundation/Foundation.h>
#import "NBUImagePickerPrivate.h"

@class NBUFileAsset;

@interface NBUAssetUtils : NSObject

/**
 * 退出应用
 */
+ (void)exitApplication;

/**
 * 获取document目录
 * @return document目录
 */
+ (NSString *)documentsDirectory;

/**
 *  在document目录下创建相册
 *  @param albumName 相册名称 eg:albumName
 *  @return 包含相册名称的路径 eg:/data/albumName
 */
+ (NSString *)createAlbum:(NSString *)albumName;

/**
 * 创建文件名称
 * @return 文件名称.jpg
 */
+ (NSString *)createFileName;

/**
 *  获取所有相册名称
 *  @return 相册名称列表
 */
+ (NSArray *)getAllAlbums;

/**
 *  保存图片
 *  @param image     图片
 *  @param albumName 相册名称 eg:album
 *  @param fileName  文件名称 eg:abc.jpg
 *  @return 保存是否成功
 */
+ (BOOL)saveImage:(UIImage *)image toAlubm:(NSString *)albumName withFileName:(NSString *)fileName;

/**
 * 保存视频
 * @param image 视频图片
 * @param albumName  相册名称 eg:album
 * @param fileName 文件名称  eg:xxx.mp4
 * @return 是否成功
 */
+ (BOOL)saveVideo:(UIImage *)image toAlubm:(NSString *)albumName fileName:(NSString *)fileName;


/**
 * 解密成图片
 * @param image NBUFileAsset
 * @return UIImage
 */
+ (UIImage *)decryImage:(NBUFileAsset *)image;

/**
 * 解密成图片
 * @param path 图片路径
 * @return
 */
+ (UIImage *)decryImageWithPath:(NSString *)path;

/**
 *  解密数据
 *  @param image     图片数据
 *  @param albumName 目标相册 eg:album
 *  @param pwd 密码
 *  @return 是否成功
 */
+ (BOOL)decryImage:(NBUFileAsset *)image toAlubm:(NSString *)albumName withPwd:(NSString *)pwd;

/**
 * 移动文件到指定相册
 * @param assert 文件
 * @param srcAlbumName 原始相册名称 eg:album1
 * @param destAlbumName 目标相册名称 eg:album2
 * @return 是否成功
 */
+ (BOOL)moveFile:(NBUFileAsset *)assert from:(NSString *)srcAlbumName toAlbum:(NSString *)destAlbumName;

/**
 * 获取视频的缩略图
 * @param filePath 视频文件路径
 * @return 缩略图
 */
+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath;


@end
