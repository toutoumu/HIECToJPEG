//
//  MWPhoto.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWPhotoProtocol.h"

@class ALAsset;

// This class models a photo/image and it's caption
// If you want to handle photos, caching, decompression
// yourself then you can simply ensure your custom data model
// conforms to MWPhotoProtocol
@interface MWPhoto : NSObject <MWPhoto>

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic) BOOL emptyImage;
@property (nonatomic) BOOL isVideo;//是否为视频
@property (nonatomic) BOOL isThumb;//是否为缩略图
@property (nonatomic) BOOL isNeedDecrypt;//是否需要解密
@property (nonatomic, copy) UIImage * (^decrypt)(NSString *);//解密方法



+ (MWPhoto *)photoWithImage:(UIImage *)image;
+ (MWPhoto *)photoWithURL:(NSURL *)url isNeedDecrypt:(BOOL) isNeedDecrypt;
+ (MWPhoto *)photoWithALAsset:(ALAsset *)url isThumb:(BOOL) isThumb;
+ (MWPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
+ (MWPhoto *)videoWithURL:(NSURL *)url; // Initialise video with no poster image

- (id)init;
- (id)initWithImage:(UIImage *)image ;
- (id)initWithURL:(NSURL *)url isNeedDecrypt:(BOOL) isNeedDecrypt;
- (id)initWithALAsset:(ALAsset *)asset isThumb:(BOOL) isThumb;
- (id)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
- (id)initWithVideoURL:(NSURL *)url;

@end

