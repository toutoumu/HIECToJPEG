// 相册列表,图片列表,图片浏览
#import <NBUKit/NBUAdditions.h>
#import "AlbumViewController.h"
#import "SelectAlbumViewController.h"
#import "UINavigationController+FDFullscreenPopGesture.h"
#import "TOCropViewController.h"

@interface AlbumViewController () <TOCropViewControllerDelegate>
@end

// 相册列表,图片列表,图片浏览
@implementation AlbumViewController {
    BOOL _isUpdated;// 相册数据,是否已经更新,如果已经更新那么需要重新加载数据
    NBUAssetsGroup *_group;// 当前相册引用
    NSMutableArray<NBUAsset *> *_asses;// 图片数据集合
    NSMutableArray *_selections;// 与图片数据集合一一对应,是否选中
    MWPhotoBrowser *_browser;
}

// 类初始化
+ (void)initialize {
    if (self == [AlbumViewController class]) {
        // 注册沙盒相册
        NSString *docDir = [NBUAssetUtils documentsDirectory];
        NSArray *array = [NBUAssetUtils getAllAlbums];
        for (NSString *album in array) {
            NSURL *url = [NSURL URLWithString:[docDir stringByAppendingPathComponent:album]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupForURL:url name:album];
        }
    }
}

// 从storyboard初始化默认会调用这个方法
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _group = nil;
        _isUpdated = NO;
        _asses = [NSMutableArray new];
        _selections = [NSMutableArray new];
    }
    return self;
}

/**
 * 状态栏样式
 * @return
 */
- (UIStatusBarStyle)preferredStatusBarStyle {//
    return UIStatusBarStyleLightContent;
}

#pragma mark - -
#pragma mark - -------生命周期方法

- (void)viewDidLoad {
    [super viewDidLoad];

    // 相册列表每一项的布局文件 Configure grid view
    self.objectTableView.nibNameForViews = @"CustomAssetsGroupView";

    // 下一个页面返回按钮标题,图片列表页面返回按钮的名称 Customization
    self.customBackButtonTitle = @"Album";

    __weak AlbumViewController *weakSelf = self;
    __block NSMutableArray *weakSelections = _selections;

    // 设置相册点击事件
    self.groupSelectedBlock = ^(NBUAssetsGroup *group) {
        [weakSelf showProgressHUDWithMessage:@"加载中..."];
        // 异步加载数据
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _group = group;
            // 初始化图片浏览器
            _browser = [[MWPhotoBrowser alloc] initWithDelegate:weakSelf];
            _browser.displayActionButton = YES;//分享按钮
            _browser.displayNavArrows = YES;//翻页箭头
            _browser.displaySelectionButtons = NO;//是否显示选择按钮
            _browser.alwaysShowControls = NO;//是否总是显示底部工具条
            _browser.zoomPhotosToFill = NO;//图片是否拉伸填充屏幕
            _browser.enableGrid = YES;//启用网格列表
            _browser.startOnGrid = YES;//从网格列表显示
            _browser.enableSwipeToDismiss = YES;
            _browser.autoPlayOnAppear = NO;//显示时播放
            _browser.currentAlbumName = group.name;//当前相册名称
            [_browser setCurrentPhotoIndex:0];
            //图片列表页面右上角按钮点击事件block
            _browser.optionButtonClickBlock = ^(MWPhotoBrowser *photoBrowser) {
                [weakSelf showOptionActionSheet];
            };

            // 加载数据
            [group assetsWithTypes:NBUAssetTypeAny
                         atIndexes:nil
                      reverseOrder:YES
               incrementalLoadSize:0
                       resultBlock:^(NSArray *assets, BOOL finished, NSError *error) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [weakSelf hideProgressHUD:NO];
                               if (error) return;
                               _asses = (NSMutableArray *) assets;
                               // 跳转到相片列表页面
                               [weakSelf.navigationController pushViewController:_browser animated:YES];
                               // 重置选中集合 Reset selections
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   if (finished) {//数据已经全部加载完成
                                       [weakSelections removeAllObjects];
                                       for (int i = 0; i < _asses.count; i++) {
                                           [weakSelections addObject:@NO];
                                       }
                                   }
                               });
                           });
                       }];
        });
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 显示导航栏
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    // 内容被状态栏挡住
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    id i = self.progressHUD;//有这一句之后进度条就没问题了
    i = nil;
    if (_isUpdated) {//如果数据有更新
        _isUpdated = NO;
        [self loadGroups];
    }

    // Authorized?
    if (![NBUAssetsLibrary sharedLibrary].userDeniedAccess) {
        // No need for info button
        self.navigationItem.rightBarButtonItem = nil;
    }
    // 禁用 iOS7 返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

#pragma mark - -
#pragma mark - -------图片浏览器协议实现 MWPhotoBrowserDelegate

#pragma mark 图片数量

/**
 *  图片数量
 *
 *  @param photoBrowser 图片浏览器引用
 *
 *  @return 图片数量
 */
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    if (_asses == nil) {
        return 0;
    }

    return _asses.count;
}

#pragma mark 全屏图片

/**
 *  构建全屏图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 全屏图片
 */
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count) {
        NBUAsset *data = _asses[index];
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return [MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset fullScreenSize]];
        }

        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        // fileURLWithPath 初始化的URL会以file:///开头,isFileURL = YES ,isFileReferenceURL = NO
        // URLWithString   初始化的URL会以 / 开头,     isFileURL = NO  ,isFileReferenceURL = NO
        NBUFileAsset *temp = (NBUFileAsset *) data;
        BOOL needDecrypt = NO;//![_group.name isEqualToString:NBUAssetUtils.HEICDirectory];//是否需要解密
        NSURL *url = [NSURL fileURLWithPath:temp.fullScreenImagePath];
        MWPhoto *photo = [MWPhoto photoWithURL:url isNeedDecrypt:needDecrypt];
        if (temp.type == NBUAssetTypeVideo) {//如果是视频那么设置视频URL
            photo.videoURL = temp.URL;
        }
        if (needDecrypt) {//需要解密的图片,提供解密方法
            photo.decrypt = decryptBlock;
        }
        return photo;
    }
    return nil;
}

#pragma mark 缩略图

/**
 *  构建缩略图
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 缩略图
 */
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count) {
        NBUAsset *data = _asses[index];
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return [MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset thumbnailSize]];
        }

        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        // fileURLWithPath 初始化的URL会以file:///开头,isFileURL = YES ,isFileReferenceURL = NO
        // URLWithString   初始化的URL会以 / 开头,     isFileURL = NO  ,isFileReferenceURL = NO
        NBUFileAsset *temp = (NBUFileAsset *) data;
        BOOL needDecrypt = NO;//![_group.name isEqualToString:NBUAssetUtils.HEICDirectory];//是否需要解密
        NSURL *url = [NSURL fileURLWithPath:temp.thumbnailImagePath];
        MWPhoto *photo = [MWPhoto photoWithURL:url isNeedDecrypt:needDecrypt];
        if (temp.type == NBUAssetTypeVideo) {//如果是视频那么设置视频URL
            photo.videoURL = temp.URL;
        }
        if (needDecrypt) {//需要解密的图片,提供解密方法
            photo.decrypt = decryptBlock;
        }
        photo.isThumb = YES;
        return photo;
    }
    return nil;
}

#pragma mark 根据索引判断图片是否选中

/**
 * 根据索引判断图片是否选中
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否选择
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    if (_asses == nil || _asses.count == 0 || _selections == nil || _selections.count == 0 || _selections[index] == nil) {
        return NO;
    }
    return [_selections[index] boolValue];
}

#pragma mark 图片选择状态改变事件

/**
 *  图片选择状态改变事件
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *  @param selected     是否被选中
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    _selections[index] = @(selected);
    NBULogInfo(@"Photo at index %lu selected %@", (unsigned long) index, selected ? @"YES" : @"NO");
}

#pragma mark 模态窗口呈现完成之后的回调

/**
 *  模态窗口呈现完成之后的回调
 *
 *  @param photoBrowser 图片浏览器引用
 */
/*- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NBULogInfo(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}*/

#pragma mark 第index张图片的标题

/**
 *  第index张图片的标题
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 标题
 */
/*- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    return [NSString stringWithFormat:@"Photo %lu", (unsigned long) index + 1];
}*/

#pragma mark 第index张图片的说明

/**
 *
 * @param photoBrowser
 * @param index
 * @return
 */
/*- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {

    NBUAsset *data = [_asses objectAtIndex:index];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:data.date];

    MWPhoto *photo = [[MWPhoto alloc] init];
    photo.caption = strDate;
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    return captionView;
}*/

#pragma mark 第index张图片将要显示

/**
 *  第index张图片将要显示
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
/*- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NBULogInfo(@"Did start viewing photo at index %lu", (unsigned long) index);
}*/

#pragma mark -  -
#pragma mark - ------文件操作相关--图片浏览器协议实现 MWPhotoBrowserDelegate

/**
 *  切换可选|不可选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true可选|false不可选
 */
#pragma mark[选择模式] &[浏览模式] 切换

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelectModel:(BOOL)select {
    if (photoBrowser.displaySelectionButtons != select) {//如果状态有改变
        photoBrowser.displaySelectionButtons = select;
        if (!select) {// 如果切换到不可选,把所有选中的取消选择
            NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
            [_selections removeAllObjects];
            for (int i = 0; i < count; i++) {
                [_selections addObject:@NO];
            }
        }
        [photoBrowser reloadGridData];
    }
}

#pragma mark[全选] 或者[取消全选]

/**
 *  设置全选或者取消全选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true全选|false取消全选
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelect:(BOOL)select {
    if (select) {//如果是全选,显示选择标记
        photoBrowser.displaySelectionButtons = YES;
    }
    NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
    [_selections removeAllObjects];//清空原来的标记
    for (int i = 0; i < count; i++) {
        [_selections addObject:@(select)];
    }
    [photoBrowser reloadGridData];
}


#pragma mark[导出] 或[解密]选择的图片

/**
 *  导出选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)exportSelected:(MWPhotoBrowser *)photoBrowser {
    // 不是沙盒文件夹文件不能执行操作
    if (![_group isMemberOfClass:[NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能导出"];
        return;
    }
    // 判断是否选择了文件
    if (![self hasSelectedItem]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
        return;
    }
    void (^exportBlock)() = ^() {// 导出或解密操作
        [photoBrowser showProgressHUDWithMessage:@"正在导出..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 获取选择的文件
            NSArray *selectedAssets = [self getSelectedItem:NO];
            //导出到系统相册
            [NBUAssetsLibrary addAll:selectedAssets toAlbum:@"HEIC" withBlock:^(NSError *error, BOOL finish, int index) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (index == selectedAssets.count) {
                        [photoBrowser setProgressMessage:@"正在保存请稍后..."];
                    } else {
                        NSString *progressMessage = [NSString stringWithFormat:@"%d/%lu", index, (unsigned long) selectedAssets.count];
                        [photoBrowser setProgressMessage:progressMessage];
                    }
                    if (finish) {// 如果已经执行完成
                        _isUpdated = true;// 由于有可能显示了系统相册所以需要更新数据
                        if (error) {// 执行完成但是出错了
                            [photoBrowser showProgressHUDCompleteMessage:@"部分导出成功"];
                            [self showAlertWithTitle:@"警告" message:@"部分文件导出成功"];
                        } else {// 正确执行完成
                            [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
                        }
                    }
                });
            }];
        });
    };
    [self showAlertWithTitle:@"警告" message:@"确定要导出?" okTitle:[NSString stringWithFormat:@"%@", @"导出"] action:exportBlock];
}

#pragma[转换] 选择的文件

- (void)convertSelected:(MWPhotoBrowser *)photoBrowser {
    // 获取选择的文件,过滤掉视频文件
    NSArray *selectedAssets = [self getSelectedItem:YES];
    if (selectedAssets.count == 0) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"请选择需要转换的文件"];
        return;
    }
    [photoBrowser showProgressHUDWithMessage:@"转换中..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {// 系统相册
            for (NSUInteger i = 0; i < selectedAssets.count; i++) {
                NBUAsset *asset = selectedAssets[i];
                NSUInteger type = [NBUAssetUtils isHEIC:asset.PHAsset] ? 1 : 0;// 0:HEIC 1:JPEG
                NSString *albumName = type == 0 ? NBUAssetUtils.HEICDirectory : NBUAssetUtils.JPEGDirectory;
                [NBUAssetUtils saveImage:asset.fullResolutionImage
                               imageData:nil
                                 toAlubm:albumName
                            withFileName:[NBUAssetUtils getFileName:type]
                              encodeType:type];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *progressMessage = [NSString stringWithFormat:@"%lu/%lu", (unsigned long) i, (unsigned long) selectedAssets.count];
                    [photoBrowser setProgressMessage:progressMessage];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                _isUpdated = YES;
                [photoBrowser showProgressHUDCompleteMessage:@"转换成功"];
            });
        } else if ([_group.name isEqualToString:NBUAssetUtils.HEICDirectory] || [_group.name isEqualToString:NBUAssetUtils.CropDirectory]) {
            for (NSUInteger i = 0; i < selectedAssets.count; i++) {
                NBUAsset *asset = selectedAssets[i];
                [NBUAssetUtils saveImage:asset.fullResolutionImage
                               imageData:nil
                                 toAlubm:NBUAssetUtils.JPEGDirectory
                            withFileName:[NBUAssetUtils getFileName:1]
                              encodeType:1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _isUpdated = YES;
                    [photoBrowser showProgressHUDCompleteMessage:@"转换成功"];
                });
            }
        } else if ([_group.name isEqualToString:NBUAssetUtils.JPEGDirectory]) {
            for (NSUInteger i = 0; i < selectedAssets.count; i++) {
                NBUAsset *asset = selectedAssets[i];
                [NBUAssetUtils saveImage:asset.fullResolutionImage
                               imageData:nil
                                 toAlubm:NBUAssetUtils.HEICDirectory
                            withFileName:[NBUAssetUtils getFileName:0]
                              encodeType:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _isUpdated = YES;
                    [photoBrowser showProgressHUDCompleteMessage:@"转换成功"];
                });
            }
        } else if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [photoBrowser showProgressHUDCompleteMessage:@"该目录文件不能转换"];
            });
        }
    });
}

#pragma mark[移动] 选择的文件

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser moveSelectedToAlbum:(NSString *)destAlbumName {
    if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
        return;
    }

    [photoBrowser showProgressHUDWithMessage:@"正在移动..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 获取需要移动的文件
        NSArray *movedArray = [self getSelectedItem:NO];
        if (movedArray.count == 0) {// 如果没有可以删除的文件
            dispatch_async(dispatch_get_main_queue(), ^{
                [photoBrowser showProgressHUDCompleteMessage:@"请选择要移动的文件"];
            });
            return;
        }
        // 如果有可以移动的文件
        for (NSUInteger i = 0; i < movedArray.count; i++) {
            NBUFileAsset *asset = movedArray[i];
            // 如果是document文件且不是Deleted相册,移动文件到目标文件夹
            BOOL success = [NBUAssetUtils moveFile:asset from:_group.name toAlbum:destAlbumName];
            if (success) {
                _isUpdated = YES;
                [_asses removeObject:asset];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *progressMessage = [NSString stringWithFormat:@"%lu/%lu", (unsigned long) i, (unsigned long) movedArray.count];
                    [photoBrowser setProgressMessage:progressMessage];
                });
            } else { // 部分删除失败
                dispatch_async(dispatch_get_main_queue(), ^{
                    [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                    [self showAlertWithTitle:@"警告" message:@"移动失败"];
                });
                break;
            }
        }
        // 重置选中项数据
        NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
        [_selections removeAllObjects];
        for (int i = 0; i < count; i++) {
            [_selections addObject:@NO];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            // 刷新数据
            [photoBrowser reloadData];
            [photoBrowser reloadGridData];
            [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
        });

    });
}

#pragma mark[删除] 选择的图片

/**
 *  删除选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)deleteSelected:(MWPhotoBrowser *)photoBrowser {
    // 检查是否有选择文件
    if (![self hasSelectedItem]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"请选择要删除的文件"];
        return;
    }

    // 如果是沙盒文件,且不是 [Deleted] 相册的文件直接移动到 [Deleted]
    if ([_group isMemberOfClass:[NBUDirectoryAssetsGroup class]] &&//是沙盒
            ![_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {//不是回收站
        // 执行文件移动操作
        [self photoBrowser:photoBrowser moveSelectedToAlbum:NBUAssetUtils.DeletedDirectory];
        return;
    }

    // 删除操作block
    void (^deleteBlock)() = ^() {
        [photoBrowser showProgressHUDWithMessage:@""];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 获取选中项中可以删除的文件
            NSArray *removedArray = [self getSelectedItem:NO];
            if (removedArray.count == 0) {// 如果没有可以删除的文件
                dispatch_async(dispatch_get_main_queue(), ^{
                    [photoBrowser showProgressHUDCompleteMessage:@"请选择要删除的文件"];
                });
                return;
            }
            // 如果有可以删除的文件
            //递归删除,注意 8.0以下系统不支持
            [_group deleteAll:[removedArray copy] withBlock:^(NSError *error, BOOL finish, NBUAsset *asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _isUpdated = YES;
                    if (asset != nil) {// 移除已经删除的文件
                        [_asses removeObject:asset];
                    }
                    if (finish) {//操作完成刷新数据
                        // 重置选中项数据
                        NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
                        [_selections removeAllObjects];
                        for (int i = 0; i < count; i++) {
                            [_selections addObject:@NO];
                        }

                        // 刷新数据
                        [photoBrowser reloadData];
                        [photoBrowser reloadGridData];
                        if (error != nil) {// 如果操作结束,但是发生了错误
                            [photoBrowser showProgressHUDCompleteMessage:@"部分删除成功"];
                            [self showAlertWithTitle:@"警告" message:@"删除失败,可能有部分文件删除成功"];
                            return;
                        }

                        [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                    }
                });
            }];

        });
    };

    if ([_group isKindOfClass:[NBUDirectoryAssetsGroup class]]) {//如果是沙盒相册
        [self showAlertWithTitle:@"警告" message:@"确定要删除,删除后文件将不可恢复?" okTitle:@"删除" action:deleteBlock];
    } else {//系统相册,系统会弹出删除确认对话框
        deleteBlock();
    }
}

#pragma mark[返回] 事件监听

/**
 * 点击返回按钮是否退出图片浏览器
 * @param photoBrowser
 * @return false 不允许退出, true 允许退出
 */
- (BOOL)isReturn:(MWPhotoBrowser *)photoBrowser {
    // 如果当前为选择模式 或者 有选择的图片那么取消选择,并设置为不可选择模式
    if (photoBrowser.displaySelectionButtons || [self hasSelectedItem]) {
        [self photoBrowser:photoBrowser toggleSelectModel:NO];
        return NO;
    }
    return YES;
}

#pragma mark[移动文件] 对话框

/**
 * [移动文件] 对话框
 * @param photoBrowser
 * @param action  1:移动选中项 2: 移动指定索引
 */
- (void)showMove:(MWPhotoBrowser *)photoBrowser action:(int)action {
    // 系统相册不允许移动
    if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
        return;
    }

    if (action == 1) {// 移动选择项需要判断这个
        if (![self hasSelectedItem]) {
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"请选择要移动的文件"];
            return;
        }
    }

    SelectAlbumViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectAlbumViewController"];
    controller.action = action;// 1:移动选中项 2: 移动指定索引
    controller.photoBrowser = photoBrowser;

    controller.onlyLoadDocument = YES;// 只加载沙盒
    // 排除当前相册和Deleted相册
    controller.excludeAlbumNames = [[NSMutableArray alloc] init];
    [controller.excludeAlbumNames addObject:_group.name];
    [controller.excludeAlbumNames addObject:NBUAssetUtils.DeletedDirectory];
    // 设置选择相册页面返回按钮文字
    photoBrowser.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                     style:UIBarButtonItemStylePlain
                                                                                    target:self
                                                                                    action:nil];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark[单张图片浏览]-- 显示裁剪页面

/**
 *
 * @param photoBrowser
 * @param image
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser showCrop:(UIImage *)image {
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleDefault image:image];
    cropController.delegate = self;
    // Uncomment this if you wish to provide extra instructions via a title label
    // cropController.title = @"Crop Image";//标题

    // -- Uncomment these if you want to test out restoring to a previous crop setting --
    //cropController.angle = 90; // 旋转角度The initial angle in which the image will be rotated
    //cropController.imageCropFrame = CGRectMake(0, 0, 2848, 4288); //The initial frame that the crop controller will have visible.

    // -- Uncomment the following lines of code to test out the aspect ratio features --
    cropController.aspectRatioPreset = TOCropViewControllerAspectRatioPresetCustom; // 裁剪的比例Set the initial aspect ratio as a square
    cropController.aspectRatioLockEnabled = NO; // 是否可以拖动改变裁剪框尺寸 The crop box is locked to the aspect ratio and can't be resized away from it
    cropController.resetAspectRatioEnabled = NO; // 重置按钮是否可以重置到默认值 When tapping 'reset', the aspect ratio will NOT be reset back to default
    cropController.aspectRatioPickerButtonHidden = NO;//是否隐藏裁剪框尺寸选择按钮
    cropController.customAspectRatio = CGSizeMake(9.0f, 16.0f);//自定义尺寸

    // -- Uncomment this line of code to place the toolbar at the top of the view controller --
    //cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;//工具类位置

    cropController.rotateButtonsHidden = NO;//旋转图片按钮是否隐藏
    cropController.rotateClockwiseButtonHidden = NO;

    //cropController.doneButtonTitle = @"Title";// 确定按钮文字
    //cropController.cancelButtonTitle = @"Title";// 取消按钮文字

    cropController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_browser presentViewController:cropController animated:YES completion:nil];
    //[self.navigationController pushViewController:cropController animated:YES];
}


#pragma mark[单张图片浏览]--[导出] 或[解密] 指定索引的图片

/**
 *  导出指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否导出成功
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser exportAtIndex:(NSUInteger)index {
    // 只有沙盒相册才能执行 [导出] 操作
    if (![_group isMemberOfClass:[NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能导出"];
        return YES;
    }

    void (^optionBlock)() = ^() {
        [photoBrowser showProgressHUDWithMessage:@"正在导出"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NBUAsset *asset = _asses[index];
            [[NBUAssetsLibrary sharedLibrary]
                    saveImageToCameraRoll:asset.fullResolutionImage
                                 metadata:nil
                 addToAssetsGroupWithName:@"HEIC"
                              resultBlock:^(NSURL *assetURL, NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      if (!error) {
                                          _isUpdated = YES;
                                          [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
                                      } else {
                                          [photoBrowser showProgressHUDCompleteMessage:@"导出失败"];
                                          [self showAlertWithTitle:@"警告" message:@"导出失败"];
                                      }
                                  });
                              }];
        });
    };
    // 弹出 [导出] 对话框
    [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确定要%@", @"导出"] okTitle:@"导出" action:optionBlock];
    return YES;
}

/**
 * 转换指定索引的图片
 * @param photoBrowser
 * @param index
 * @param option 转换选项 0:HEIC 1:JPEG
 * @return
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser convertAtIndex:(NSUInteger)index option:(NSUInteger)option {
    NBUAsset *asset = _asses[index];
    if (asset.type == NBUAssetTypeVideo) {
        [photoBrowser showProgressHUDCompleteMessage:@"视频文件无法转换"];
        return NO;
    }
    NSString *message = option == 0 ? @"转换为HEIC" : @"转换为JPEG";
    NSString *albumName = option == 0 ? NBUAssetUtils.HEICDirectory : NBUAssetUtils.JPEGDirectory;
    void (^optionBlock)() = ^() {
        [photoBrowser showProgressHUDWithMessage:[NSString stringWithFormat:@"正在%@", message]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *fileName = [NBUAssetUtils getFileName:option];
            BOOL success = [NBUAssetUtils saveImage:asset.fullResolutionImage imageData:nil toAlubm:albumName withFileName:fileName encodeType:option];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    _isUpdated = YES;
                    [photoBrowser showProgressHUDCompleteMessage:@"转换成功"];
                } else {
                    [photoBrowser showProgressHUDCompleteMessage:@"转换失败"];
                    [self showAlertWithTitle:@"警告" message:@"转换失败"];
                }
            });
        });
    };
    // 弹出对话框
    [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确定要%@", message] okTitle:message action:optionBlock];
    return YES;
}

#pragma mark[单张图片浏览]--移动指定索引的图片

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser moveAtIndex:(NSUInteger)index toAlbum:(NSString *)destAlbumName {
    // 检查数据
    if (_asses == nil || _asses.count == 0 || _asses[index] == nil) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"数据异常,移动失败"];
        return NO;
    }

    if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册不能移动"];
        return NO;
    }

    [photoBrowser showProgressHUDWithMessage:@"正在移动..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NBUFileAsset *temp = (NBUFileAsset *) _asses[index];
        BOOL success = [NBUAssetUtils moveFile:temp from:_group.name toAlbum:destAlbumName];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                _isUpdated = YES;
                [_asses removeObject:temp];
                [_selections removeObjectAtIndex:index];
                [photoBrowser reloadData];
                [photoBrowser reloadGridData];
                [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
            } else {
                [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                [self showAlertWithTitle:@"警告" message:@"移动失败"];
            }
        });
    });
    return YES;
}

#pragma mark[单张图片浏览]--删除指定索引的图片

/**
 *  删除指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否删除成功
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deleteAtIndex:(NSUInteger)index {

    void (^moveToDeleteBlock)()=^() {// 移动到回收站
        if (_asses == nil || _asses.count == 0 || _asses[index] == nil) {// 如果没有数据
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"数据异常,移动到回收站失败"];
            return;
        }
        [photoBrowser showProgressHUDWithMessage:@"移动到回收站..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 移动文件
            NBUFileAsset *temp = (NBUFileAsset *) _asses[index];
            BOOL success = [NBUAssetUtils moveFile:temp from:_group.name toAlbum:NBUAssetUtils.DeletedDirectory];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    _isUpdated = YES;
                    [_selections removeObjectAtIndex:index];
                    [_asses removeObject:temp];
                    [photoBrowser reloadData];
                    [photoBrowser reloadGridData];
                    [photoBrowser showProgressHUDCompleteMessage:@"移动到回收站成功"];
                } else {//移动文件失败
                    [photoBrowser showProgressHUDCompleteMessage:@"移动到回收站失败"];
                    [self showAlertWithTitle:@"警告" message:@"移动到回收站失败"];
                }
            });
        });
    };

    void (^deleteBlock)() = ^() {// 删除文件
        if (_asses == nil || _asses.count == 0 || _asses[index] == nil) {// 如果没有数据
            [photoBrowser showProgressHUDWithMessage:@"数据异常,删除失败"];
            [photoBrowser showProgressHUDCompleteMessage:@"数据异常,删除失败"];
            return;
        }
        [photoBrowser showProgressHUDWithMessage:@"正在删除..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NBUAsset *asset = _asses[index];
            // 删除文件
            [asset delete:^(NSError *error, BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error == nil) {
                        _isUpdated = YES;
                        [_selections removeObjectAtIndex:index];
                        [_asses removeObject:asset];
                        [photoBrowser reloadData];
                        [photoBrowser reloadGridData];
                        [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                    } else {
                        [photoBrowser showProgressHUDCompleteMessage:@"删除失败"];
                        [self showAlertWithTitle:@"警告" message:@"删除失败"];
                    }
                });
            }];

        });
    };

    if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {//系统相册直接删除
        deleteBlock();
    } else if ([_group isMemberOfClass:[NBUDirectoryAssetsGroup class]]) {
        if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            // 如果是 回收站文件,删除文件
            [self showAlertWithTitle:@"警告" message:@"确定要删除,删除后文件将不可恢复?" okTitle:@"删除" action:deleteBlock];
        } else {// 移动到回收站
            moveToDeleteBlock();
        }
    }
    return YES;
}


#pragma mark[单张图片浏览]--右下角的按钮

/**
 *  点击分享操作按钮后的回调,如果设置了这个那么默认的将不会显示 [单张图片右下角的按钮]
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    void (^deleteBlock)() = ^() {// 删除
        [photoBrowser.delegate photoBrowser:photoBrowser deleteAtIndex:index];
    };

    void (^exportBlock)() = ^() {// 导出
        [photoBrowser.delegate photoBrowser:photoBrowser exportAtIndex:index];
    };

    void (^editBlock)() = ^() {// 编辑
        [self photoBrowser:photoBrowser showCrop:_asses[index].fullResolutionImage];
    };

    void (^convertHEICBlock)() = ^() {// 转换为HEIC
        [photoBrowser.delegate photoBrowser:photoBrowser convertAtIndex:index option:0];
    };

    void (^convertJPEGBlock)() = ^() {// 转换为JPEG
        [photoBrowser.delegate photoBrowser:photoBrowser convertAtIndex:index option:1];
    };

    void (^moveBlock)() = ^() {// 移动指定索引 1:移动选中项 2: 移动指定索引
        [photoBrowser.delegate showMove:photoBrowser action:2];
    };

    void (^putBack)()=^() {// 回收站文件,放回原处
        if (![_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"该文件不能执行此操作"];
            return;
        }
        NBUFileAsset *asset = (NBUFileAsset *) _asses[index];
        if (asset == nil) {
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"数据有误"];
            return;
        }
        [photoBrowser showProgressHUDWithMessage:@"正在放回原处..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Boolean success;
            if ([[asset.fullResolutionImagePath lowercaseString] hasSuffix:@".heic"]) {
                success = [NBUAssetUtils moveFile:asset from:_group.name toAlbum:NBUAssetUtils.HEICDirectory];
            } else {
                success = [NBUAssetUtils moveFile:asset from:_group.name toAlbum:NBUAssetUtils.JPEGDirectory];
            }
            if (success) {
                _isUpdated = YES;
                [_asses removeObject:asset];
                // 重置选中项数据
                NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
                [_selections removeAllObjects];
                for (int i = 0; i < count; i++) {
                    [_selections addObject:@NO];
                }
                dispatch_async(dispatch_get_main_queue(), ^{// 刷新数据
                    [photoBrowser reloadData];
                    [photoBrowser reloadGridData];
                    [photoBrowser showProgressHUDCompleteMessage:@"文件已经放回原处"];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{// 刷新数据
                    [photoBrowser showProgressHUDCompleteMessage:@"操作失败"];
                });
            }
        });
    };

    if (@available(ios 11.0, *)) {
        // 系统相册图片根据实际类型进行转换
        if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {
            NBUAsset *asset = _asses[index];
            bool isHEIC = [NBUAssetUtils isHEIC:asset.PHAsset];
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:isHEIC ? @"转换JPEG" : @"转换为HEIC" action:isHEIC ? convertJPEGBlock : convertHEICBlock],
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock], nil]
                    showInView:photoBrowser.view];
            return;
        }

        // Crop和HEIC文件夹的文件,已经是HEIC格式
        if ([_group.name isEqualToString:NBUAssetUtils.CropDirectory] ||
                [_group.name isEqualToString:NBUAssetUtils.HEICDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动到回收站" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"转换为JPEG" action:convertJPEGBlock],
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock],
                         [RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil]
                    showInView:photoBrowser.view];
            return;
        }
        // JPEG文件夹的文件为JPEG类型
        if ([_group.name isEqualToString:NBUAssetUtils.JPEGDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动到回收站" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"转换为HEIC" action:convertHEICBlock],
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock],
                         [RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil]
                    showInView:photoBrowser.view];
            return;
        }

        // 回收站的文件不清楚文件类型
        if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"放回原处" action:putBack],
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock],
                         [RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil]
                    showInView:photoBrowser.view];
            return;
        }
    } else {// IOS 11以下系统
        if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {// 系统相册
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock], nil]
                    showInView:photoBrowser.view];
        } else if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {// 回收站的文件
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock],
                         [RIButtonItem itemWithLabel:@"移动" action:moveBlock],
                         [RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil]
                    showInView:photoBrowser.view];
            return;
        } else {// 其他文件目录
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择对该图片的操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
                 }]
            destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动到回收站" action:deleteBlock]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"编辑" action:editBlock],
                         [RIButtonItem itemWithLabel:@"移动" action:moveBlock],
                         [RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil]
                    showInView:photoBrowser.view];
            return;
        }
    }
}

#pragma mark - -
#pragma mark - ------私有方法

#pragma mark 是否有选择的文件

/**
 * 是否有选择的文件
 * @param ignoreVideo 是否忽略视频文件
 * @return
 */
- (BOOL)hasSelectedItem {
    if (_selections != nil && _selections.count > 0) {
        for (NSUInteger i = 0; i < _selections.count; i++) {
            if ([_selections[i] boolValue]) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 * 获取选择的文件
 * @param ignoreVideo 是否忽略视频文件
 * @return
 */
- (NSArray *)getSelectedItem:(BOOL)ignoreVideo {
    // 获取选择的文件
    NSMutableArray *selectedAssets = [[NSMutableArray alloc] init];
    if (_selections != nil && _selections.count > 0) {
        for (NSUInteger i = 0; i < _selections.count; i++) {
            if (![_selections[i] boolValue]) {
                continue;//如果未选中结束本次循环
            }
            if (ignoreVideo && _asses[i].type == NBUAssetTypeVideo) {
                continue;//如果是视频文件结束本次循环
            }
            [selectedAssets addObject:_asses[i]];
        }
    }
    return selectedAssets;
}


#pragma mark 权限验证 Handling access authorization

- (void)accessInfo:(id)sender {
    // 如果用户不允许访问 User denied access?
    if ([NBUAssetsLibrary sharedLibrary].userDeniedAccess) {
        [self showAlertWithTitle:@"Access denied" message:@"Please go to Settings:Privacy:Photos to enable library access"];
    }
    // 如果设置不允许访问 Parental controls
    if ([NBUAssetsLibrary sharedLibrary].restrictedAccess) {
        [self showAlertWithTitle:@"Parental restrictions" message:@"Please go to Settings:General:Restrictions to enable library access"];
    }
}

#pragma mark 显示警告信息

/**
 * 显示警告信息
 * @param message 警告信息
 */
- (void)showWarning:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"警告"
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"确定" action:nil]
                       otherButtonItems:nil] show];

}

#pragma mark 显示警告信息

/**
 * 显示警告信息
 * @param title 标题
 * @param message 警告信息
 */
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"确定" action:nil]
                       otherButtonItems:nil] show];
}

#pragma mark 显示确认取消对话框

/**
 * 显示确认取消对话框
 * @param title 标题
 * @param message 信息
 * @param okTitle 确定按钮文本
 * @param action 确定按钮执行的操作
 */
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message okTitle:(NSString *)okTitle action:(void (^)(void))action {
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:nil]
                       otherButtonItems:[RIButtonItem itemWithLabel:okTitle action:action], nil] show];
}

#pragma mark - -
#pragma mark - ------进度条相关方法
#pragma mark 进度条

/**
 * _progressHUD get方法
 * @return
 */
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

#pragma mark 显示进度条信息

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.label.text = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD showAnimated:YES];
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

#pragma mark 隐藏进度条

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hideAnimated:animated];
    self.fd_interactivePopDisabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark 显示1.6秒信息提示

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD showAnimated:YES];
        self.progressHUD.label.text = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hideAnimated:YES afterDelay:0.6];
    } else {
        [self.progressHUD hideAnimated:YES];
    }
    //这里修改了,为了解决删除文件时候,右滑返回,会在弹窗时候可用
    //self.fd_interactivePopDisabled = NO;
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    //弹出的时候禁用,1.6秒之后启用
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    double delayInSeconds = 1.6;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        self.fd_interactivePopDisabled = NO;
        self.navigationController.navigationBar.userInteractionEnabled = YES;
    });
}

#pragma mark 设置进度条消息

- (void)setProgressMessage:(NSString *)message {
    if (message) {
        if (_progressHUD != nil && !_progressHUD.isHidden) {
            self.progressHUD.label.text = message;
        }
    }
}


#pragma mark - -
#pragma mark - ------图片裁剪协议实现 TOCropViewControllerDelegate

#pragma mark 裁剪成长方形图片回调

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle {
    [_browser dismissViewControllerAnimated:YES completion:^{
        [_browser showProgressHUDWithMessage:@"保存中..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 保存到Crop目录
            BOOL success = [NBUAssetUtils saveImage:image imageData:nil
                                            toAlubm:NBUAssetUtils.CropDirectory
                                       withFileName:[NBUAssetUtils getFileName:0]
                                         encodeType:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    _isUpdated = YES;
                    [_browser showProgressHUDCompleteMessage:@"保存成功"];
                } else {
                    [_browser showProgressHUDCompleteMessage:@"保存失败"];
                }
            });
        });
    }];
}

#pragma mark 裁剪成圆形图片回调

- (void)cropViewController:(nonnull TOCropViewController *)cropViewController didCropToCircularImage:(nonnull UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle {

}

#pragma mark - -
#pragma mark 文件解密Block

/**
 * 文件解密Block
 * @return 解密后的图片
 */
UIImage *(^decryptBlock)(NSString *) = ^UIImage *(NSString *path) {
    return [NBUAssetUtils decryImageWithPath:path];
};


#pragma mark --
#pragma mark 图片列表页面右上角按钮点击事件, 调用的方法

- (void)showOptionActionSheet {
    if (_browser == nil || _group == nil) {
        return;
    }

    void (^putBack)()=^() {// 放回原处
        if (![_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            [_browser showProgressHUDWithMessage:@""];
            [_browser showProgressHUDCompleteMessage:@"该文件不能执行此操作"];
            return;
        }
        // 获取选择的文件
        NSArray *selectedAssets = [self getSelectedItem:NO];
        if (selectedAssets.count == 0) {
            [_browser showProgressHUDWithMessage:@""];
            [_browser showProgressHUDCompleteMessage:@"请选择文件"];
            return;
        }

        [_browser showProgressHUDWithMessage:@"正在放回原处..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (NSUInteger i = 0; i < selectedAssets.count; i++) {
                NBUFileAsset *asset = selectedAssets[i];
                if (asset == nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_browser showProgressHUDWithMessage:@""];
                        [_browser showProgressHUDCompleteMessage:@"数据有误"];
                    });
                    return;
                }

                if ([[asset.fullResolutionImagePath lowercaseString] hasSuffix:@".heic"]) {
                    [NBUAssetUtils moveFile:asset from:_group.name toAlbum:NBUAssetUtils.HEICDirectory];
                } else {
                    [NBUAssetUtils moveFile:asset from:_group.name toAlbum:NBUAssetUtils.JPEGDirectory];
                }
                [_asses removeObject:asset];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // 重置选中项数据
                NSUInteger count = [self numberOfPhotosInPhotoBrowser:_browser];
                [_selections removeAllObjects];
                for (int i = 0; i < count; i++) {
                    [_selections addObject:@NO];
                }

                // 刷新数据
                _isUpdated = YES;
                [_browser reloadData];
                [_browser reloadGridData];
                [_browser showProgressHUDCompleteMessage:@"文件已经放回原处"];
            });
        });
    };

    if (@available(iOS 11.0, *)) {
        if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {// 系统相册
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"删除选中项" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"转换选中项" action:^{// 转换选择项
                             if (![self hasSelectedItem]) {
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择需要转换的文件"];
                                 return;
                             }
                             [self showAlertWithTitle:@"提示" message:@"确定要转换?" okTitle:@"转换" action:^() {
                                 [_browser.delegate convertSelected:_browser];
                             }];
                         }], nil
            ] showInView:_browser.view];
        } else if ([_group.name isEqualToString:NBUAssetUtils.HEICDirectory] ||
                [_group.name isEqualToString:NBUAssetUtils.JPEGDirectory] ||
                [_group.name isEqualToString:NBUAssetUtils.CropDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"移动到回收站" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"转换选中项" action:^{// 转换选择项
                             if (![self hasSelectedItem]) {
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择需要转换的文件"];
                                 return;
                             }
                             [self showAlertWithTitle:@"提示" message:@"确定要转换?" okTitle:@"转换" action:^() {
                                 [_browser.delegate convertSelected:_browser];
                             }];
                         }],
                         [RIButtonItem itemWithLabel:@"导出选中项" action:^{//导出选择项
                             if (![self hasSelectedItem]) {// 判断是否选择了文件
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
                                 return;
                             }
                             [_browser.delegate exportSelected:_browser];
                         }], nil
            ] showInView:_browser.view];
        } else if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"删除" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"放回原处" action:putBack],
                         [RIButtonItem itemWithLabel:@"转换选中项" action:^{// 转换选择项
                             if (![self hasSelectedItem]) {
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择需要转换的文件"];
                                 return;
                             }
                             [self showAlertWithTitle:@"提示" message:@"确定要转换?" okTitle:@"转换" action:^() {
                                 [_browser.delegate convertSelected:_browser];
                             }];
                         }],
                         [RIButtonItem itemWithLabel:@"导出选中项" action:^{//导出选择项
                             if (![self hasSelectedItem]) {// 判断是否选择了文件
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
                                 return;
                             }
                             [_browser.delegate exportSelected:_browser];
                         }], nil
            ] showInView:_browser.view];
        }
    } else {// IOS 11以下系统
        if ([_group isMemberOfClass:[NBUPHAssetsGroup class]]) {// 系统相册
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"删除选中项" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }], nil
            ] showInView:_browser.view];
        } else if ([_group.name isEqualToString:NBUAssetUtils.HEICDirectory] ||
                [_group.name isEqualToString:NBUAssetUtils.JPEGDirectory] ||
                [_group.name isEqualToString:NBUAssetUtils.CropDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"移动到回收站" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"移动选择项" action:^{// 移动选择项
                             [_browser.delegate showMove:_browser action:1];
                         }],
                         [RIButtonItem itemWithLabel:@"导出选中项" action:^{//导出选择项
                             if (![self hasSelectedItem]) {// 判断是否选择了文件
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
                                 return;
                             }
                             [_browser.delegate exportSelected:_browser];
                         }], nil
            ] showInView:_browser.view];
        } else if ([_group.name isEqualToString:NBUAssetUtils.DeletedDirectory]) {
            [[[UIActionSheet alloc]
                    initWithTitle:@"选择操作"
                 cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
            destructiveButtonItem:
                    [RIButtonItem itemWithLabel:@"删除" action:^{
                        [_browser.delegate deleteSelected:_browser];
                    }]
                 otherButtonItems:
                         [RIButtonItem itemWithLabel:@"全选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"全不选" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelect:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"选择模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:YES];
                         }],
                         [RIButtonItem itemWithLabel:@"浏览模式" action:^{
                             [_browser.delegate photoBrowser:_browser toggleSelectModel:NO];
                         }],
                         [RIButtonItem itemWithLabel:@"移动选择项" action:^{// 移动选择项
                             [_browser.delegate showMove:_browser action:1];
                         }],
                         [RIButtonItem itemWithLabel:@"导出选中项" action:^{//导出选择项
                             if (![self hasSelectedItem]) {// 判断是否选择了文件
                                 [_browser showProgressHUDWithMessage:@""];
                                 [_browser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
                                 return;
                             }
                             [_browser.delegate exportSelected:_browser];
                         }], nil
            ] showInView:_browser.view];
        }
    }
};

#pragma mark - ------
@end
