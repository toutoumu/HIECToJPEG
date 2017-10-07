//
//  PhotoViewController.m
//  PickerDemo
//
//  Created by LiuBin on 16/1/10.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//

#import "GalleryViewController.h"

@interface GalleryViewController ()

@end

@implementation GalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isUpdated = NO;
    self.imagePreloadCount = 2;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 删除照片

- (IBAction)deleteImage:(UIBarButtonItem *)sender {
    NBUAsset *data = self.objectArray[self.currentIndex];
    if (data && data.URL) {
        [[[UIAlertView alloc] initWithTitle:@"警告"
                                    message:@"确定要删除?"
                                   delegate:self
                          cancelButtonTitle:@"取消"
                          otherButtonTitles:@"确定", nil] show];
    }
}

#pragma mark 删除照片弹窗监听

//根据被点击按钮的索引处理点击事件
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {//点击确定
        NBUAsset *data = self.objectArray[self.currentIndex];
        if (data && data.URL) {
            //if ([NBUAssetUtils deletePhotoByURL:data.URL]) {
            [data delete:^(NSError *error, BOOL success) {
                if (error == nil) {
                    [self.objectArray removeObject:data];
                    if (self.objectArray.count > 0) {
                        [self reloadGallery];
                    } else if (self.objectArray.count == 0) {
                        [self.navigationController popViewController:self];
                    }

                    self.isUpdated = YES;
                }
            }];
        }
    }
}


#pragma mark - 导出文件

- (IBAction)exportImage:(id)sender {
    NBUAsset *data = self.objectArray[self.currentIndex];
    if (data && data.URL) {
        [self saveImageToPhotos:data.fullResolutionImage];
    }
}

#pragma mark 保存图片到相册

- (void)saveImageToPhotos:(UIImage *)savedImage {
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

#pragma mark UIImageWriteToSavedPhotosAlbum方法回调

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil;
    if (error != NULL) {
        msg = @"保存图片失败";
    } else {
        msg = @"保存图片成功";
    }
    [[[UIAlertView alloc] initWithTitle:@"提示"
                                message:msg
                               delegate:self
                      cancelButtonTitle:@"确定"
                      otherButtonTitles:nil] show];

}


@end
