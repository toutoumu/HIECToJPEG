//
//  TTFIleUtils.h
//  PickerDemo
//
//  Created by LiuBin on 16/1/13.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface TTFIleUtils : NSObject


/**
 *  在document目录下创建相册
 *
 *  @param albumName 相册名称
 *
 *  @return 相册路径
 */
+ (NSString *) createAlbum:(NSString *)albumName;

/**
 *  获取所有相册名称
 *
 *  @return 相册名称列表
 */
+(NSArray *) getAllAlbums;

/**
 *  保存图片
 *
 *  @param image     图片
 *  @param albumName 相册名称
 *  @param fileName  图片名称
 *
 *  @return 保存是否成功
 */
+(BOOL) saveImage:(UIImage*)image toAlubm:(NSString*) albumName ;

/**
 *  删除相片
 *
 *  @param fileName  文件名
 *  @param albumName 相册名称
 *
 *  @return 删除是否成功
 */
+(BOOL)deletePhoto:(NSString*)fileName toAlbum:(NSString*)albumName;


/**
 *  删除相片
 *
 *  @param url 相片url
 *
 *  @return 删除是否成功
 */
+(BOOL)deletePhotoByURL:(NSURL*)url ;



/**
 * 移动文件到指定相册
 *  @param fileName  文件
 *  @param albumName 相册名称
 */
+(BOOL)moveFile:(NBUFileAsset *)assert from:(NSString *)srcAlbumName toAlbum:(NSString *)destAlbumName;

/**
 *  旋转照片到正确的方向
 */
+ (UIImage *)fixOrientation:(UIImage *)aImage;
@end
