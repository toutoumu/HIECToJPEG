//
//  TTFIleUtils.h
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NBUFileAsset;

@interface NBUAssetUtils : NSObject

+ (NSString *)getPassword;

+ (void)setPassword:(NSString *)password;

#pragma mark 退出应用

+ (void)exitApplication;

#pragma mark 获取Document目录

+ (NSString *)documentsDirectory;

/**
 *  在document目录下创建相册
 *
 *  @param albumName 相册名称
 *
 *  @return 相册路径
 */
+ (NSString *)createAlbum:(NSString *)albumName;

/**
 *  获取所有相册名称
 *
 *  @return 相册名称列表
 */
+ (NSArray *)getAllAlbums;

/**
 *  保存图片
 *
 *  @param image     图片
 *  @param albumName 相册名称
 *
 *  @return 保存是否成功
 */
+ (BOOL)saveImage:(UIImage *)image toAlubm:(NSString *)albumName;

+ (BOOL)saveVideo:(UIImage *)image toAlubm:(NSString *)albumName fileName:(NSString *)fileName;


/**
 *  解密数据
 *
 *  @param image     图片数据
 *  @param albumName 目标相册
 *
 *  @return 是否成功
 */
+ (BOOL)dencryImage:(NBUFileAsset *)image toAlubm:(NSString *)albumName;

/**
 * 移动文件到指定相册
 * @param assert 文件
 * @param srcAlbumName 原始相册名称
 * @param destAlbumName 目标相册名称
 * @return 是否成功
 */
+ (BOOL)moveFile:(NBUFileAsset *)assert from:(NSString *)srcAlbumName toAlbum:(NSString *)destAlbumName;


+ (UIImage *)getScreenShotImageFromVideoPath:(NSString *)filePath;


@end
