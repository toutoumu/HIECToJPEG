//
//  SelectAlbumViewController.m
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "SelectAlbumViewController.h"

@implementation SelectAlbumViewController

+ (void)initialize {
    if (self == [SelectAlbumViewController class]) {
        // 注册沙盒相册
        NSString *docDir = [NBUAssetUtils documentsDirectory];
        NSArray *array = [NBUAssetUtils getAllAlbums];
        for (NSString *album in array) {
            NSURL *url = [NSURL URLWithString:[docDir stringByAppendingPathComponent:album]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupForURL:url name:album];
        }
    }
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];

    // 相册列表每一项的布局文件 Configure grid view
    self.objectTableView.nibNameForViews = @"CustomAssetsGroupView";

    // 下一个页面返回按钮标题,图片列表页面返回按钮的名称 Customization
    self.customBackButtonTitle = @"Cancel";

    __weak SelectAlbumViewController *weakSelf = self;
    __weak MWPhotoBrowser *weakPhotoBrowser = _photoBrowser;
    // 设置相册点击事件, 设置了之后上面的图片列表将会失效
    self.groupSelectedBlock = ^(NBUAssetsGroup *group) {
        // 移动照片
        [[[UIAlertView alloc] initWithTitle:@"警告"
                                    message:[NSString stringWithFormat:@"确定要移动到 %@", group.name]
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                           }]
                           otherButtonItems:[RIButtonItem itemWithLabel:@"确定" action:^{
                               if (_action == 1) {//1:导出选中项 2: 导出指定索引
                                   [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveSelectedToAlbum:group.name];
                               } else if (_action == 2) {
                                   [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveAtIndex:weakPhotoBrowser.currentIndex toAlbum:group.name];
                               }
                           }], nil] show];
        [weakSelf.navigationController popViewController:weakSelf];
    };
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // 显示标题栏
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    // 设置状态栏样式
    //[self setNavBarAppearance:animated];
}

/**
 * 状态栏文字样式
 * @return UIStatusBarStyle
 */
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Authorized?
    if (![NBUAssetsLibrary sharedLibrary].userDeniedAccess) {
        // No need for info button
        self.navigationItem.rightBarButtonItem = nil;
    }
}


#pragma mark 设置导航栏样式

- (void)setNavBarAppearance:(BOOL)animated {
    // 显示标题栏
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.tintColor = [UIColor whiteColor];
    navigationBar.barTintColor = nil;
    navigationBar.shadowImage = nil;
    navigationBar.translucent = YES;
    navigationBar.barStyle = UIBarStyleBlack;
    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
}

#pragma mark 递归导出

/**
 *  递归导出或解密照片
 *
 *  @param data         照片数据
 *  @param index        当前要导出的相片的索引
 *  @param photoBrowser 图片浏览器引用
 */
- (void)export:(NSArray *)data atIndex:(int)index photoBrowser:(MWPhotoBrowser *)photoBrowser {
//    // 如果已经循环到最后一项
//    if (index < 0 || index > data.count -1) {
//        if(index == data.count){//导出或解密成功
//            dispatch_async(dispatch_get_main_queue(), ^ {
//                NSString *message = @"解密";
//                if([photoBrowser.currentAlbumName isEqualToString:@"Decrypted"]){
//                    message = @"导出";
//                }
//                [photoBrowser showProgressHUDCompleteMessage:[NSString stringWithFormat:@"%@成功",message]];
//            });
//        }
//        return;
//    }
//    
//    NBUAsset * asset = [data objectAtIndex:index];
//    if ([asset isMemberOfClass:[NBUFileAsset class]] ) {
//        // 处理解密文件夹文件---导出解密文件
//        if([photoBrowser.currentAlbumName isEqualToString:@"Decrypted"]){
//            [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll: [NBUAssetUtils fixOrientation:asset.fullResolutionImage]
//                                                           metadata:nil
//                                           addToAssetsGroupWithName:@"test"
//                                                        resultBlock:^(NSURL * assetURL,
//                                                                      NSError * saveError)
//             {
//                 NSString *message = [NSString stringWithFormat:@"%d/%lu", index + 1, (unsigned long)data.count];
//                 [photoBrowser setProgressMessage:message];
//                 _isUpdated = YES;
//                 if (saveError == nil) {
//                     [self export:data atIndex:index + 1 photoBrowser:photoBrowser];
//                 }else{
//                     dispatch_async(dispatch_get_main_queue(), ^ {
//                         [photoBrowser showProgressHUDCompleteMessage:@"部分导出成功"];
//                         [self showAlertWithTitle:@"警告" message:@"导出失败"];
//                     });
//                 }
//             }];
//            return;
//        }
//        // 处理加密文件夹文件----解密文件
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            BOOL isSuccess = [NBUAssetUtils dencryImage:(NBUFileAsset *) asset toAlubm:@"Decrypted"];
//            NSString *message = [NSString stringWithFormat:@"%d/%lu", index + 1, (unsigned long)data.count];
//            dispatch_async(dispatch_get_main_queue(), ^ {
//                [photoBrowser setProgressMessage:message];
//                if(!isSuccess){//解密失败
//                    [photoBrowser showProgressHUDCompleteMessage:@"部分解密成功"];
//                    [self showAlertWithTitle:@"警告" message:@"部分解密成功"];
//                }
//            });
//            if (isSuccess) {
//                _isUpdated = YES;
//                [self export:data atIndex:index + 1 photoBrowser:photoBrowser];
//            }
//        });
//        
//    }
}


#pragma mark 递归删除

/**
 *  递归删除照片
 *
 *  @param data         照片数据
 *  @param index        当前要删除的相片的索引
 *  @param photoBrowser 图片浏览器引用
 */
- (void)delete:(NSArray *)data atIndex:(int)index photoBrowser:(MWPhotoBrowser *)photoBrowser {
    // 如果已经循环到最后一项
//    if (index < 0 || index >= data.count) {
//        if(index == data.count){// 如果已经循环到最后一项
//            // 重置选中项数据
//            NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
//            [_selections removeAllObjects];
//            for (int i = 0; i < count; i++) {
//                [_selections addObject:[NSNumber numberWithBool:NO]];
//            }
//            dispatch_async(dispatch_get_main_queue(), ^ {
//                // 刷新数据
//                [photoBrowser reloadData];
//                [photoBrowser reloadGridData];
//                [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
//            });
//        }
//        return;
//    }
//    // 如果不是最后一项
//    NBUAsset * asset = [data objectAtIndex:index];
//    // 如果是 [沙箱] 文件且不是Deleted或Decrypted相册文件夹,移动文件到Deleted相册文件夹
//    if([asset isMemberOfClass:[NBUFileAsset class]] && ![photoBrowser.currentAlbumName isEqualToString:@"Deleted"]&& ![photoBrowser.currentAlbumName isEqualToString:@"Decrypted"]){
//        BOOL b = [NBUAssetUtils moveFile:(NBUFileAsset *)asset from:photoBrowser.currentAlbumName toAlbum:@"Deleted"];
//        if (b) {
//            _isUpdated = YES;
//            [_asses removeObject:asset];
//            [self delete:data atIndex:index + 1 photoBrowser:photoBrowser];
//        }else{ // 部分删除失败
//            dispatch_async(dispatch_get_main_queue(), ^ {
//                [photoBrowser showProgressHUDCompleteMessage:@"部分删除成功"];
//                [self showAlertWithTitle:@"警告" message:@"部分删除成功"];
//            });
//        }
//    }else {
//        [asset delete:^(NSError *error, BOOL success) {
//            if (error == nil ) {
//                _isUpdated = YES;
//                [_asses removeObject:asset];
//                [self delete:data atIndex:index + 1 photoBrowser:photoBrowser];
//            }else{ // 部分删除失败
//                dispatch_async(dispatch_get_main_queue(), ^ {
//                    [photoBrowser showProgressHUDCompleteMessage:@"部分删除成功"];
//                    [self showAlertWithTitle:@"警告" message:@"部分删除成功"];
//                });
//            }
//        }];
//    }
}


@end
