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
                               if (_action == 1) {// 1:移动选中项 2: 移动指定索引
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

@end
