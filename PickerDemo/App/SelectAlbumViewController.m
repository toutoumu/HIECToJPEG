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
        for (NSString *alubm in array) {
            NSURL *url = [NSURL URLWithString:[docDir stringByAppendingPathComponent:alubm]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupforURL:url name:alubm];
        }
    }
}

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    // 只加载沙盒相册,必须在 [super viewDidLoad];之前才有效
    self.onlyLoadDocument = YES;

    [super viewDidLoad];

    // 相册列表每一项的布局文件 Configure grid view
    self.objectTableView.nibNameForViews = @"CustomAssetsGroupView";

    // 下一个页面返回按钮标题,图片列表页面返回按钮的名称 Customization
    self.customBackButtonTitle = @"Cancel";

    __weak SelectAlbumViewController *weakSelf = self;
    __weak MWPhotoBrowser *weakPhotoBrowser = _photoBrowser;
    // 设置相册点击事件, 设置了之后上面的图片列表将会失效
    self.groupSelectedBlock = ^(NBUAssetsGroup *group) {
        if (group) {
            // 移动照片
            if (_action == 1) {//1:导出选中项 2: 导出指定索引
                [[[UIAlertView alloc] initWithTitle:@"警告"
                                            message:[NSString stringWithFormat:@"确定要移动到 %@", group.name]
                                   cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                                   }]
                                   otherButtonItems:[RIButtonItem itemWithLabel:@"确定" action:^{
                                       [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveSelectedToAlbum:group.name];
                                   }], nil] show];


//                UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"选择操作"
//                                                            cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
//                                                       destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动" action:^{
//                    [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveSelectedToAlbum:group.name] ;
//                }]
//                                                            otherButtonItems:nil];
//                [sheet showInView:weakSelf.view];
            } else if (_action == 2) {//1:导出选中项 2: 导出指定索引
                [[[UIAlertView alloc] initWithTitle:@"警告"
                                            message:[NSString stringWithFormat:@"确定要移动到 %@", group.name]
                                   cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                                   }]
                                   otherButtonItems:[RIButtonItem itemWithLabel:@"确定" action:^{
                                       [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveAtIndex:weakPhotoBrowser.currentIndex toAlbum:group.name];
                                   }], nil] show];

//                UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"选择操作"
//                                                            cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
//                                                       destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动" action:^{
//                    [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveAtIndex:weakPhotoBrowser.currentIndex toAlbum:group.name];
//                }]
//                                                            otherButtonItems:nil];
//                [sheet showInView:weakSelf.view];
            }
            [weakSelf.navigationController popViewController:weakSelf];
        }
    };
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

//    // 获取前一项(UIViewcontrol)因为是count所以,减一是代表自己,减二代表前一个页面 We're not first so show back button
//    UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
//    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
//    // Appearance
//    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsCompact];
//    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
//    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsCompact];
//    [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
//    [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
//    previousViewController.navigationItem.backBarButtonItem = newBackButton;

    // 状态栏样式
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    [self setNavBarAppearance:animated];
    // 显示标题栏
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
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
//                if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
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
//        if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
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
//    if([asset isMemberOfClass:[NBUFileAsset class]] && ![photoBrowser.currentAlbulName isEqualToString:@"Deleted"]&& ![photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
//        BOOL b = [NBUAssetUtils moveFile:(NBUFileAsset *)asset from:photoBrowser.currentAlbulName toAlbum:@"Deleted"];
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
