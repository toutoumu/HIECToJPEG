//
//  PhotosViewController.m
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "PhotosViewController.h"
#import "GalleryViewController.h"

@interface PhotosViewController () {
    // 底部菜单栏,注意继承<UIActionSheetDelegate>协议
    UIActionSheet *sheet;
    // 是否为浏览模式
    BOOL isScan;
}

@end


@implementation PhotosViewController

#pragma mark - 生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];

    isScan = YES; //默认为浏览模式
    self.isUpdated = NO;//默认为不更新数据

    // 配置图片显示样式 Configure the grid view
    self.gridView.margin = CGSizeMake(4.0, 4.0);
    self.gridView.nibNameForViews = @"CustomAssetThumbnailView";

    // Configure the selection behaviour
    self.selectionCountLimit = 0;//选择多少张--无限制
    self.loadSize = 40;//一次加载多少张
    self.reverseOrder = YES;//排序反转

    // 编辑按钮
    _editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(setEdit:)];
    self.navigationItem.rightBarButtonItem = _editButton;

    // 底部弹出菜单
    sheet = [[UIActionSheet alloc] initWithTitle:@"Select Belgian Beer Style"
                                        delegate:self
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:nil
                               otherButtonTitles:@"Select All", @"DeSelect All", @"Delete Selected", @"Select", @"Scan", @"Export", nil];

    // 相册界面
    //UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    _galleryViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GalleryViewController"];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    GalleryViewController *controll = (GalleryViewController *) _galleryViewController;
    if (controll && controll.isUpdated) {
        controll.isUpdated = NO;
        [self update];
    }
}

// 页面消失
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // Stop loading assets?
    if (!self.navigationController) {
        [self.assetsGroup stopLoadingAssets];
    }
}

#pragma mark - 协议方法实现
#pragma mark 根据被点击按钮的索引处理点击事件

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([self.selectedAssetsURLs count] > 0) {
            for (NSUInteger i = 0; i < [self.selectedAssetsURLs count]; i++) {
                //[NBUAssetUtils deletePhotoByURL:[self.selectedAssetsURLs objectAtIndex:i]];
                NBUAsset *asset = self.selectedAssets[i];
                [asset delete:nil];
            }
            [self update];
        }
    }
}

#pragma mark 底部弹出菜单点击事件监听

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NBULogInfo(@"点击了第几项 Button %li", (long) buttonIndex);
    switch (buttonIndex) {
        case 0://select all
            [self selectAll:nil];
            isScan = NO;
            break;
        case 1://deSelect all
            [self deSelectAll:nil];
            isScan = NO;
            break;
        case 2://delete selected
            if ([self.selectedAssetsURLs count] > 0) {
                [[[UIAlertView alloc] initWithTitle:@"警告"
                                            message:@"确定要删除?"
                                           delegate:self
                                  cancelButtonTitle:@"取消"
                                  otherButtonTitles:@"确定", nil] show];
            }

            isScan = NO;
            break;
        case 3://Select
            isScan = NO;
            break;
        case 4://Scan
            isScan = YES;
            [self deSelectAll:nil];
            break;
        case 5://exprot
            if ([self.selectedAssets count] > 0) {
                NSUInteger count = [self.selectedAssets count];
                for (NSUInteger i = 0; i < count; i++) {
                    NBUAsset *asset = self.selectedAssets[i];
                    [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll:asset.fullResolutionImage
                                                                   metadata:nil
                                                   addToAssetsGroupWithName:@"test"
                                                                resultBlock:nil];
                }
            }
            break;
        default:
            break;
    }
}


#pragma mark 编辑按钮点击事件

- (IBAction)setEdit:(id)sender {
    [sheet showInView:self.view];
}

#pragma mark 重载-相册图片点击事件

- (void)thumbnailViewSelectionStateChanged:(NSNotification *)notification {
    if (!isScan) {//如果不是浏览模式那么就是选择模式,调用父类的方法
        [super thumbnailViewSelectionStateChanged:notification];
        return;
    }
    // 获取点击的缩略图
    NBUAssetThumbnailView *assetView = (NBUAssetThumbnailView *) notification.object;
    // 获取点击项索引
    NSUInteger index = [self.assets indexOfObject:assetView.asset];

    // 设置相册数据
    _galleryViewController.objectArray = self.assets;
    _galleryViewController.currentIndex = index;
    // 取消缩略图选择
    assetView.selected = NO;
    // 跳转页面
    [self.navigationController pushViewController:_galleryViewController animated:YES];
}


#pragma mark 全选

- (void)selectAll:(id)sender {
    [self setSelectedAssets:self.assets];
}

#pragma mark 取消全选

- (void)deSelectAll:(id)sender {
    NSArray *array = [[NSArray alloc] init];
    [self setSelectedAssets:array];
}

#pragma 更新数据

- (void)update {
    [self objectUpdated:@{NBUObjectUpdatedTypeKey: NBUObjectUpdatedTypeNewObject}];
    _isUpdated = YES;
}


@end
