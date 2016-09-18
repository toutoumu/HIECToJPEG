//
//  Test.m
//  PickerDemo
//
//  Created by LiuBin on 1/25/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "Test.h"
@import Photos;

@implementation Test
-(void) test{
    if (YES) {
        // 列出所有相册智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [smartAlbums enumerateObjectsUsingBlock:^(PHCollection *obj, NSUInteger idx, BOOL *stop){
            NSLog(@"相册名称:%@",obj.localizedTitle);
        }];
        
        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        [topLevelUserCollections enumerateObjectsUsingBlock:^(PHCollection *obj, NSUInteger idx, BOOL *stop){
            NSLog(@"相册名称:%@",obj.localizedTitle);
        }];
        // 获取所有资源的集合，并按资源的创建时间排序
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        
        // 在资源的集合中获取第一个集合，并获取其中的图片
        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
        PHAsset *asset = assetsFetchResults[10];
        
        
        
        // 读取url 旋转方向信息
        PHImageRequestOptions *options1 = [[PHImageRequestOptions alloc] init];
        options1.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:options1
                                                    resultHandler:
         ^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
             NSDictionary * _phAssetInfo = info;
             //CIImage* ciImage = [CIImage imageWithData:imageData];
         }];
        
        [imageManager requestImageForAsset:asset
                                targetSize:[NBUAsset thumbnailSize]
                               contentMode:PHImageContentModeAspectFill
                                   options:nil
                             resultHandler:^(UIImage *result, NSDictionary *info) {
                                 UIImage *image = result;
                                 // 得到一张 UIImage，展示到界面上
                                 
                             }];
        return;
    }
}
@end
