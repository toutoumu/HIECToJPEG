// 相册列表,图片列表,图片浏览
#import "AlbumViewController.h"
#import "TTFIleUtils.h"
#import "PhotosViewController.h"
#import "MWPhotoBrowser.h"
#import "NBUAssetsGroup.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SelectAlbumViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "UINavigationController+FDFullscreenPopGesture.h"

// 相册列表,图片列表,图片浏览
@interface AlbumViewController (){
    BOOL _isUpdated;// 相册数据,是否已经更新,如果已经更新那么需要重新加载数据
    NSMutableArray * _asses;// 图片数据集合
    NSMutableArray *_selections;// 与图片数据集合一一对应,是否选中
    NBUAssetsGroup * _group;// 当前相册引用
}

@end
// 相册列表,图片列表,图片浏览
@implementation AlbumViewController

// 类初始化
+(void)initialize{
    if (self == [AlbumViewController class]){
        // 注册沙盒相册
        NSString *docDir = [TTFIleUtils documentsDirectory];
        NSArray *array = [TTFIleUtils getAllAlbums];
        for (NSString *alubm in array) {
            NSURL *url = [NSURL URLWithString:[docDir stringByAppendingPathComponent: alubm]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupforURL:url name: alubm];
        }
    }
}

// 对象初始化
- (void)setUp{
    _group = nil;
    _isUpdated = NO;
    _asses = [NSMutableArray new];
    _selections = [NSMutableArray new];
}

#pragma mark - 生命周期方法
- (void)viewDidLoad{
    self.onlyLoadDocument = YES;// 只显示沙盒相册
    
    [super viewDidLoad];
    
    // 初始化各种值
    [self setUp];
    
    // 相册列表每一项的布局文件 Configure grid view
    self.objectTableView.nibNameForViews = @"CustomAssetsGroupView";
    
    // 下一个页面返回按钮标题,图片列表页面返回按钮的名称 Customization
    self.customBackButtonTitle = @"Albums";
    
    __weak AlbumViewController * weakSelf = self;
    __block NSMutableArray *weakSelections = _selections;
    
    // 图片列表对应的controller
    //self.assetsGroupController = [self.storyboard instantiateViewControllerWithIdentifier:@"photosViewController"];
    // 设置相册点击事件, 设置了之后上面的图片列表(self.assetsGroupController)将会失效
    self.groupSelectedBlock = ^(NBUAssetsGroup * group){
        [weakSelf showProgressHUDWithMessage:@"加载中..."];
        // 异步加载数据
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _group = group;
            // 初始化图片浏览器
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:weakSelf];
            browser.displayActionButton = YES;//分享按钮
            browser.displayNavArrows = YES;//翻页箭头
            browser.displaySelectionButtons = NO;//是否显示选择按钮
            browser.alwaysShowControls = NO;//是否总是显示底部工具条
            browser.zoomPhotosToFill = YES;
            browser.enableGrid = YES;//启用网格列表
            browser.startOnGrid = YES;//从网格列表显示
            browser.enableSwipeToDismiss = YES;
            browser.autoPlayOnAppear = NO;//显示时播放
            browser.currentAlbulName = group.name;//当前相册名称
            browser.optionButtonClickBlock = optionButtonClickBlock;//图片列表页面右上角按钮点击事件block
            [browser setCurrentPhotoIndex:0];
            
            [group assetsWithTypes:NBUAssetTypeAny
                         atIndexes:nil
                      reverseOrder:YES
               incrementalLoadSize:0
                       resultBlock:^(NSArray * assets, BOOL finished, NSError * error){
                           dispatch_async(dispatch_get_main_queue(), ^ {
                               [weakSelf hideProgressHUD:NO];
                               if (error) return ;
                               _asses = (NSMutableArray *) assets;
                               // 跳转到相片列表页面
                               [weakSelf.navigationController pushViewController:browser animated:YES];
                               //[weakSelf presentViewController:_browser animated:YES completion:nil];
                               // 重置选中集合 Reset selections
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                   if (finished) {//数据已经全部加载完成
                                       [weakSelections removeAllObjects];
                                       for (int i = 0; i < _asses.count; i++) {
                                           [weakSelections addObject:[NSNumber numberWithBool:NO]];
                                       }
                                   }
                               });
                           });
                       }];
        });
    };
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // 状态栏样式
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    [self setNavBarAppearance:animated];
    
    // 内容被状态栏挡住
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //原来的图片列表页面
    /*PhotosViewController *controller = (PhotosViewController *) self.assetsGroupController;
     if (controller.isUpdated) {
     controller.isUpdated = NO;
     [self loadGroups];
     }*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    id i = self.progressHUD;//有这一句之后进度条就没问题了
    i = nil;
    if (_isUpdated) {//如果数据有更新
        _isUpdated = NO;
        [self loadGroups];
    }
    
    // Authorized?
    if (![NBUAssetsLibrary sharedLibrary].userDeniedAccess)
    {
        // No need for info button
        self.navigationItem.rightBarButtonItem = nil;
    }
    // 禁用 iOS7 返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
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


#pragma mark - 图片浏览器协议实现 MWPhotoBrowserDelegate
/**
 *  图片数量
 *
 *  @param photoBrowser 图片浏览器引用
 *
 *  @return 图片数量
 */
#pragma mark 图片数量
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    if(_asses == nil){
        return 0;
    }
    
    return _asses.count;
}

/**
 *  构建全屏图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 全屏图片
 */
#pragma mark 构建全屏图片
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count){
        NBUAsset * data = [_asses objectAtIndex:index];
        ALAsset *asset = data.ALAsset;
        if (asset) {//8.x以下系统,如果是访问相册图片那么使用url可以异步加载
            //MWPhoto *photo = [MWPhoto photoWithURL: asset.defaultRepresentation.url];
            MWPhoto *photo = [MWPhoto photoWithALAsset:asset isThumb:NO];
            if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                photo.videoURL = asset.defaultRepresentation.url;
            }
            return photo;
        }
        
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return [MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset fullScreenSize]];
        }
        
        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        // fileURLWithPath 初始化的URL会以file:///开头,isFileURL = YES ,isFileReferenceURL = NO
        // URLWithString   初始化的URL会以 / 开头,     isFileURL = NO  ,isFileReferenceURL = NO
        NBUFileAsset *temp = (NBUFileAsset *)data;
        BOOL needDecrypt = ![_group.name isEqualToString:@"Decrypted"];//是否需要解密
        NSURL *url = [NSURL fileURLWithPath:temp.fullScreenImagePath];
        MWPhoto * photo =  [MWPhoto photoWithURL: url isNeedDecrypt:needDecrypt];
        if (temp.type == NBUAssetTypeVideo) {//如果是视频那么设置视频URL
            photo.videoURL = temp.URL;
        }
        return photo;
    }
    return nil;
}

/**
 *  构建缩略图
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 缩略图
 */
#pragma mark构建缩略图
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count){
        NBUAsset * data = [_asses objectAtIndex:index];
        
        ALAsset *asset = data.ALAsset;
        if (asset) {//8.x以下系统,如果是访问相册图片那么使用url可以异步加载
            MWPhoto *photo = [MWPhoto photoWithALAsset:asset isThumb:YES];
            if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                photo.videoURL = asset.defaultRepresentation.url;
            }
            return photo;
        }
        
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return [MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset thumbnailSize]];
        }
        
        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        // fileURLWithPath 初始化的URL会以file:///开头,isFileURL = YES ,isFileReferenceURL = NO
        // URLWithString   初始化的URL会以 / 开头,     isFileURL = NO  ,isFileReferenceURL = NO
        NBUFileAsset *temp = (NBUFileAsset *)data;
        BOOL needDecrypt = ![_group.name isEqualToString:@"Decrypted"];//是否需要解密
        NSURL *url = [NSURL fileURLWithPath:temp.thumbnailImagePath];
        MWPhoto * photo =  [MWPhoto photoWithURL: url isNeedDecrypt:needDecrypt];
        if (temp.type == NBUAssetTypeVideo) {//如果是视频那么设置视频URL
            photo.videoURL = temp.URL;
        }
        return photo;
    }
    return nil;
}

/*- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
    
    NBUAsset * data = [_asses objectAtIndex:index];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:data.date];
    
    MWPhoto *photo = [[MWPhoto alloc]init];
    photo.caption = strDate;
    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    return captionView;
}*/

/**
 *  第index张图片将要显示
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NBULogInfo(@"Did start viewing photo at index %lu", (unsigned long)index);
}

/**
 * 根据索引判断图片是否选中
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否选择
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    if(_asses == nil || _asses.count == 0 || _selections == nil || _selections.count == 0 ||[_selections objectAtIndex:index] == nil){
        return NO;
    }
    return [[_selections objectAtIndex:index] boolValue];
}

/**
 *  第index张图片的标题
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 标题
 */
//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
  //  return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

/**
 *  图片选择状态改变事件
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *  @param selected     是否被选中
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NBULogInfo(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

/**
 *  模态窗口呈现完成之后的回调
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NBULogInfo(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 图片浏览器协议实现 MWPhotoBrowserDelegate 文件操作相关

/**
 *  切换可选|不可选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true可选|false不可选
 */
#pragma mark 切换可选|不可选
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelectModel:(BOOL)select{
    if (photoBrowser.displaySelectionButtons != select) {//如果状态有改变
        photoBrowser.displaySelectionButtons = select;
        if(select == NO){// 如果切换到不可选,把所有选中的取消选择
            NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
            [_selections removeAllObjects];
            for (int i = 0; i < count; i++) {
                [_selections addObject:[NSNumber numberWithBool:NO]];
            }
        }
        [photoBrowser reloadGridData];
    }
}

/**
 *  设置全选或者取消全选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true全选|false取消全选
 */
#pragma mark 设置全选或者取消全选
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelect:(BOOL)select{
    if (select) {//如果是全选,显示选择标记
        photoBrowser.displaySelectionButtons = YES;
    }
    NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
    [_selections removeAllObjects];//清空原来的标记
    for (int i = 0; i < count; i++) {
        [_selections addObject:[NSNumber numberWithBool:select]];
    }
    [photoBrowser reloadGridData];
}


/**
 *  导出选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
#pragma mark 导出或解密选择的图片
-(void)exportSelected:(MWPhotoBrowser *)photoBrowser{
    NSString *message = @"解密";
    if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
        message = @"导出";
    }
    // 不是沙盒文件夹文件不能执行操作
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage: [NSString stringWithFormat:@"该相册文件不能%@",message]];
        return ;
    }
    void (^exportBlock)() = ^(){// 导出或解密操作
        [photoBrowser showProgressHUDWithMessage:message];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 获取选择的文件
            NSMutableArray *selectedAssets = [[NSMutableArray alloc]init];
            if (_selections != nil && _selections.count > 0) {
                for (int i = 0; i < _selections.count; i++) {
                    if ([[_selections objectAtIndex:i] boolValue]) {
                        NBUAsset *asset =  [_asses objectAtIndex:i];
                        [selectedAssets addObject:asset];
                    }
                }
            }
            
            if (selectedAssets.count == 0) {// 如果没有可以操作的文件
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage: [NSString stringWithFormat:@"请选择要%@的文件",message]];//@"请选择要导出的文件"];
                });
                return ;
            }
            if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){//导出到系统相册
                //NSMutableArray * array = [[NSMutableArray alloc]init];
                //for (NBUFileAsset *asset in selectedAssets) {
                //    [array addObject:asset.fullResolutionImage];
                //}
                [NBUAssetsLibrary addAll:selectedAssets toAlbum:@"test" withBlock:^(NSError *error, BOOL fihisn,int index){
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        if (index == selectedAssets.count) {
                            [photoBrowser setProgressMessage:@"正在保存请稍后..."];
                        }else{
                            NSString *message = [NSString stringWithFormat:@"%d/%lu", index, (unsigned long)selectedAssets.count];
                            [photoBrowser setProgressMessage:message];
                        }
                        if (fihisn) {// 如果已经执行完成
                            _isUpdated = true;// 由于有可能显示了系统相册所以需要更新数据
                            if (error) {// 执行完成但是出错了
                                [photoBrowser showProgressHUDCompleteMessage:@"部分导出成功"];
                                [self showAlertWithTitle:@"警告" message:@"导出失败"];
                            }else{// 正确执行完成
                                [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
                            }
                        }
                    });
                }];
            }else{//解密文件
                int i = 0;
                for (NBUFileAsset *asset in selectedAssets) {
                    i ++;
                    BOOL isSuccess = [TTFIleUtils dencryImage:(NBUFileAsset *) asset toAlubm:@"Decrypted"];
                    NSString *message = [NSString stringWithFormat:@"%d/%lu", i, (unsigned long)selectedAssets.count];
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [photoBrowser setProgressMessage:message];
                        if(!isSuccess){//解密失败
                            [photoBrowser showProgressHUDCompleteMessage:@"部分解密成功"];
                            [self showAlertWithTitle:@"警告" message:@"部分解密成功"];
                        }
                        if(i == selectedAssets.count){//解密成功
                            [photoBrowser showProgressHUDCompleteMessage:@"解密成功"];
                        }
                    });
                    if (isSuccess) {
                        _isUpdated = YES;
                    }
                    if (!isSuccess) {
                        return ;
                    }
                }
                [photoBrowser showProgressHUDCompleteMessage:[NSString stringWithFormat:@"%@成功",message]];
            }//end of 解密文件
        });
    };
    [self showAlertWithTitle:@"警告" message:[NSString stringWithFormat:@"确定要%@?",message] okTitle:[NSString stringWithFormat:@"%@",message] action:exportBlock];
}

#pragma mark 移动选择的文件
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser  moveSelectedToAlbum:(NSString *) destAlbumName {
    [photoBrowser showProgressHUDWithMessage:@"正在移动"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *movedArray = [[NSMutableArray alloc] init];
        if (_selections != nil && _selections.count > 0) {
            // 获取选中项中可以移动的文件
            for (int i = 0; i < _selections.count; i++) {
                if ([[_selections objectAtIndex:i] boolValue]) {
                    NBUAsset *asset =  [_asses objectAtIndex:i];
                    if (asset.isEditable) {
                        [movedArray addObject:asset];
                    }
                }
            }
        }
        if (movedArray.count == 0) {// 如果没有可以删除的文件
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDCompleteMessage:@"请选择要移动的文件"];
            });
            return ;
        }
        // 如果有可以移动的文件
        for (int i = 0; i < movedArray.count; i++) {
            NBUAsset * asset = [movedArray objectAtIndex:i];
            // 如果是document文件且不是Deleted相册,移动文件到目标文件夹
            if([asset isMemberOfClass:[NBUFileAsset class]]){
                BOOL success = [TTFIleUtils moveFile:(NBUFileAsset *)asset from:photoBrowser.currentAlbulName toAlbum:destAlbumName];
                if (success) {
                    _isUpdated = YES;
                    [_asses removeObject:asset];
                }else{ // 部分删除失败
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                        [self showAlertWithTitle:@"警告" message:@"移动失败"];
                    });
                    break;
                }
            }
        }
        // 重置选中项数据
        NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
        [_selections removeAllObjects];
        for (int i = 0; i < count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
        dispatch_async(dispatch_get_main_queue(), ^ {
            // 刷新数据
            [photoBrowser reloadData];
            [photoBrowser reloadGridData];
            [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
        });
        
    });
}

/**
 *  删除选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
#pragma mark 删除选择的图片
-(void)deleteSelected:(MWPhotoBrowser *)photoBrowser{
    // 沙盒文件夹中的加密相册,删除操作直接移动到Deleteed相册
    // 如果是 [沙箱] 文件且不是Deleted或Decrypted相册文件夹,移动文件到Deleted相册文件夹
    if([_group isMemberOfClass:[NBUDirectoryAssetsGroup class]] &&//是沙盒
       ![photoBrowser.currentAlbulName isEqualToString:@"Deleted"]&&//不是回收站
       ![photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){//不是解密文件夹
        [self photoBrowser:photoBrowser moveSelectedToAlbum:@"Deleted"];
        return;
    }
    
    //删除操作block
    void (^deleteBlock)() = ^(){
        [photoBrowser showProgressHUDWithMessage:@""];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *removedArray = [[NSMutableArray alloc] init];
            if (_selections != nil && _selections.count > 0) {
                // 获取选中项中可以删除的文件
                for (int i = 0; i < _selections.count; i++) {
                    if ([[_selections objectAtIndex:i] boolValue]) {
                        NBUAsset *asset =  [_asses objectAtIndex:i];
                        if (asset.isEditable) {
                            [removedArray addObject:asset];
                        }
                    }
                }
            }
            if (removedArray.count == 0) {// 如果没有可以删除的文件
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage:@"请选择要删除的文件"];
                });
                return ;
            }
            // 如果有可以删除的文件
            //递归删除,注意 8.0以下系统不支持
            [_group deleteAll:[removedArray copy] withBlock:^(NSError *error,BOOL finish,NBUAsset *asset){
                dispatch_async(dispatch_get_main_queue(), ^ {
                    _isUpdated = YES;
                    if (asset != nil) {// 移除已经删除的文件
                        [_asses removeObject:asset];
                    }
                    if(finish){//操作完成刷新数据
                        // 重置选中项数据
                        NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
                        [_selections removeAllObjects];
                        for (int i = 0; i < count; i++) {
                            [_selections addObject:[NSNumber numberWithBool:NO]];
                        }
                        
                        // 刷新数据
                        [photoBrowser reloadData];
                        [photoBrowser reloadGridData];
                        if (error != nil) {// 如果操作结束,但是发生了错误
                            [photoBrowser showProgressHUDCompleteMessage:@"部分删除成功"];
                            [self showAlertWithTitle:@"警告" message:@"删除失败,可能有部分文件删除成功"];
                            return ;
                        }

                        [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                    }
                });
            }];
            
        });
    };
    if ([_group isKindOfClass: [NBUDirectoryAssetsGroup class]]) {//如果是沙盒相册
        [self showAlertWithTitle:@"警告" message:@"确定要删除,删除后文件将不可恢复?" okTitle:@"删除" action: deleteBlock];
    }else{//系统相册
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {// 8.0以上系统
            deleteBlock();
        }else{
            [self showAlertWithTitle:@"警告" message:@"确定要删除,删除后文件将不可恢复?" okTitle:@"删除" action: deleteBlock];
        }
    }
}

/**
 *  导出指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否导出成功
 */
#pragma mark [单张图片浏览]导出或解密指定索引的图片
-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser exportAtIndex:(NSUInteger)index{
    NSString *message = @"解密";
    if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
        message = @"导出";
    }
    // 如果当前不是沙盒相册
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:[NSString stringWithFormat:@"该相册文件不能%@", message]];
        return YES;
    }
    
    if (_asses == nil || _asses.count == 0 || [_asses objectAtIndex:index] == nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [photoBrowser showProgressHUDWithMessage:@"数据异常,删除失败"];
            [photoBrowser showProgressHUDCompleteMessage:@"数据异常,删除失败"];
        });
        return YES;// 如果没有数据
    }
    
    NBUAsset *asset = [_asses objectAtIndex:index];
    if (asset == nil) return YES;// 如果当前项为空

    [photoBrowser showProgressHUDWithMessage:[NSString stringWithFormat:@"正在%@", message]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){//导出---解密相册导出到系统相册
            [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll: [TTFIleUtils fixOrientation:asset.fullResolutionImage]
                                                           metadata:nil
                                           addToAssetsGroupWithName:@"test"
                                                        resultBlock:^(NSURL * assetURL, NSError * error){
                                                            dispatch_async(dispatch_get_main_queue(), ^ {
                                                                if (!error) {
                                                                    _isUpdated = YES;
                                                                    [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
                                                                }else{
                                                                    [photoBrowser showProgressHUDCompleteMessage:@"导出失败"];
                                                                    [self showAlertWithTitle:@"警告" message:@"导出失败"];
                                                                }
                                                            });
                                                        }];
        }else{// 解密---加密相册解密到解密相册
            if ([asset isMemberOfClass:[NBUFileAsset class]] ) {
                BOOL b = [TTFIleUtils dencryImage:(NBUFileAsset *) asset toAlubm:@"Decrypted"];
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (b) {
                        [photoBrowser showProgressHUDCompleteMessage:@"解密成功"];
                        _isUpdated = YES;
                    }else{
                        [photoBrowser showProgressHUDCompleteMessage:@"解密失败"];
                        [self showAlertWithTitle:@"警告" message:@"解密失败"];
                    }
                });
            }
        }
    });
    
    return YES;
}

#pragma mark [单张图片浏览]移动当前项
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser moveAtIndex:(NSUInteger)index toAlbum:(NSString *) destAlbumName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 检查数据
        if (_asses == nil || _asses.count == 0 || [_asses objectAtIndex:index] == nil) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@"数据异常,删除失败"];
                [photoBrowser showProgressHUDCompleteMessage:@"数据异常,删除失败"];
            });
            return ;
        }
        
        NBUAsset *asset = [_asses objectAtIndex:index];
        if (![asset isMemberOfClass:[NBUFileAsset class]]) {
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@""];
                [photoBrowser showProgressHUDCompleteMessage:@"该相册不能移动"];
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [photoBrowser showProgressHUDWithMessage:@"正在移动..."];
        });
        NBUFileAsset *temp = (NBUFileAsset *)asset;
        BOOL success = [TTFIleUtils moveFile:temp from:photoBrowser.currentAlbulName toAlbum:destAlbumName];
        dispatch_async(dispatch_get_main_queue(), ^ {
            if (success) {
                _isUpdated = YES;
                [_selections removeObjectAtIndex:index];
                [_asses removeObjectAtIndex:index];
                [photoBrowser reloadData];
                if(_asses.count == 0){//全部移动完成才刷新这个否则会有bug
                    [photoBrowser reloadGridData];
                }
                [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
            }else{
                [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                [self showAlertWithTitle:@"警告" message:@"移动失败"];
            }
        });
    });
    return YES;
}

/**
 *  删除指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否删除成功
 */
#pragma mark [单张图片浏览]删除指定索引的图片
-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deleteAtIndex:(NSUInteger)index{
    void (^moveToDeleteBlock)()=^(){// 移动到 Deleted 相册
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (_asses == nil || _asses.count == 0 ||  [_asses objectAtIndex:index] == nil) {// 如果没有数据
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDWithMessage:@"数据异常,删除失败"];
                    [photoBrowser showProgressHUDCompleteMessage:@"数据异常,删除失败"];
                });
                return ;
            }
            
            NBUAsset *asset = [_asses objectAtIndex:index];
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@"删除..."];
                if (!asset.isEditable) {
                    [photoBrowser showProgressHUDCompleteMessage:@"不能删除"];
                }
            });
            
            // 移动文件
            NBUFileAsset *temp = (NBUFileAsset *)asset;
            BOOL success = [TTFIleUtils moveFile:temp from:photoBrowser.currentAlbulName toAlbum:@"Deleted"];
            dispatch_async(dispatch_get_main_queue(), ^ {
                if (success) {
                    _isUpdated = YES;
                    [_selections removeObjectAtIndex:index];
                    [_asses removeObjectAtIndex:index];
                    [photoBrowser reloadData];
                    if(_asses.count == 0){//全部移动完成才刷新这个否则会有bug
                        [photoBrowser reloadGridData];
                    }
                    [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                }else{//移动文件失败
                    [photoBrowser showProgressHUDCompleteMessage:@"删除失败"];
                    [self showAlertWithTitle:@"警告" message:@"删除失败"];
                }
            });
        });
    };
    
    void (^deleteBlock)() = ^(){// 删除文件
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (_asses == nil || _asses.count == 0 ||  [_asses objectAtIndex:index] == nil) {// 如果没有数据
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDWithMessage:@"数据异常,删除失败"];
                    [photoBrowser showProgressHUDCompleteMessage:@"数据异常,删除失败"];
                });
                return ;
            }

            NBUAsset *asset = [_asses objectAtIndex:index];
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@"正在删除..."];
                if (!asset.isEditable) {
                    [photoBrowser showProgressHUDCompleteMessage:@"不能删除"];
                }
            });
            // 删除文件
            [asset delete:^(NSError *error, BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    if (error == nil) {
                        _isUpdated = YES;
                        [_selections removeObjectAtIndex:index];
                        [_asses removeObjectAtIndex:index];
                        [photoBrowser reloadData];
                        if(_asses.count == 0){//全部移动完成才刷新这个否则会有bug
                            [photoBrowser reloadGridData];
                        }
                        [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                        
                    }else{
                        [photoBrowser showProgressHUDCompleteMessage:@"删除失败"];
                        [self showAlertWithTitle:@"警告" message:@"删除失败"];
                    }
                });
            }];
            
        });
    };
    
    if([_group isMemberOfClass:[NBUDirectoryAssetsGroup class]]){
        if ([photoBrowser.currentAlbulName isEqualToString:@"Deleted"] || [photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]) {
            // 如果是 Deleted ,或者 Decrypted 相册,删除文件
            [self showAlertWithTitle:@"警告" message:@"确定要删除,删除后文件将不可恢复?" okTitle:@"删除" action:deleteBlock];
        }else{// 移动到 Deleted 相册
            moveToDeleteBlock();
        }
    }else{//系统相册
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {// 8.0以上系统
            deleteBlock();
        }else{
           [self showAlertWithTitle:@"警告" message:@"确定要删除?" okTitle:@"删除" action:deleteBlock];
        }
    }
    return YES;
}



#pragma mark 点击返回按钮是否退出图片浏览器
-(BOOL)isReturn:(MWPhotoBrowser *)photoBrowser {
    if ([self hasSelectedItem]) {
        return NO;//不能退出
    }
    return YES;//退出
}

#pragma mark 网格列表页面,显示移动对话框
- (void)showMove:(MWPhotoBrowser *)photoBrowser action:(int) action{
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]|| [photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
        return ;
    }
    
    if (action == 1) {// 移动选择项需要判断这个
        if (![self hasSelectedItem]) {
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage: @"请选择要移动的文件"];
            return;
        }
    }
    
    SelectAlbumViewController *controll = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectAlbumViewController"];
    controll.onlyLoadDocument = YES;// 只加载沙盒
    // 排除当前相册和Deleted相册
    controll.action = action;// 1:导出选中项 2: 导出指定索引
    controll.photoBowser = photoBrowser;
    controll.excludeAlbumNames = [[NSMutableArray alloc]init];
    [controll.excludeAlbumNames insertObject:photoBrowser.currentAlbulName atIndex:0];
    [controll.excludeAlbumNames insertObject:@"Deleted" atIndex:0];
    [controll.excludeAlbumNames insertObject:@"Decrypted" atIndex:0];
    // 设置选择相册页面返回按钮文字
    photoBrowser.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:nil];
    [self.navigationController pushViewController:controll animated:YES];
}

/**
 *  点击分享操作按钮后的回调,如果设置了这个那么默认的将不会显示 [单张图片右下角的按钮]
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
#pragma mark 单张图片右下角的按钮
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    void (^deleteBlock)() = ^(){// 删除
        [photoBrowser.delegate photoBrowser:photoBrowser deleteAtIndex:index];
    };
    void (^exportBlock)() = ^(){// 导出或解密
        [photoBrowser.delegate photoBrowser:photoBrowser exportAtIndex:index];
    };
    
    void (^moveBlock)() = ^(){// 移动指定索引 1:导出选中项 2: 导出指定索引
        [photoBrowser.delegate showMove:photoBrowser action:2];
    };
    
    NSString * message = @"解密";
    if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
        message = @"导出";
    }
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"导出到相册"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                                                otherButtonItems:
                             [RIButtonItem itemWithLabel:message action:exportBlock],
                             [RIButtonItem itemWithLabel:@"移动" action:moveBlock],nil];
    [sheet showInView:photoBrowser.view];
}

#pragma mark - ------私有方法
#pragma mark 是否有选择的文件
-(BOOL)hasSelectedItem {
    if (_selections != nil && _selections.count > 0) {
        for (int i = 0; i < _selections.count; i++) {
            if ([[_selections objectAtIndex:i] boolValue] ) {
                return YES;
            }
        }
    }
    return NO;
}


#pragma mark 权限验证 Handling access authorization
- (void)accessInfo:(id)sender{
    // 如果用户不允许访问 User denied access?
    if ([NBUAssetsLibrary sharedLibrary].userDeniedAccess){
        [self showAlertWithTitle:@"Access denied" message:@"Please go to Settings:Privacy:Photos to enable library access"];
    }
    // 如果设置不允许访问 Parental controls
    if ([NBUAssetsLibrary sharedLibrary].restrictedAccess){
        [self showAlertWithTitle:@"Parental restrictions" message:@"Please go to Settings:General:Restrictions to enable library access"];
    }
}

#pragma mark 显示警告信息
-(void) showWarning:(NSString*) message{
    [[[UIAlertView alloc] initWithTitle: @"警告"
                                message: message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"确定" action:nil]
                       otherButtonItems: nil] show];
    
}

#pragma mark 显示警告信息
- (void) showAlertWithTitle:(NSString*) title message:(NSString*) message {
    [[[UIAlertView alloc] initWithTitle: title
                                message: message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"确定" action:nil]
                       otherButtonItems: nil] show];
}
#pragma mark 显示确认取消对话框
- (void) showAlertWithTitle:(NSString*) title message:(NSString*) message  okTitle:(NSString*)okTitle action:(void(^)(void))action{
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:nil]
                       otherButtonItems:[RIButtonItem itemWithLabel:okTitle action:action], nil] show];
}


#pragma mark - Action Progress
#pragma mark 进度条
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

#pragma mark 显示进度条
- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

#pragma mark 隐藏进度条
- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.fd_interactivePopDisabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark 显示0.6秒信息提示
- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:0.6];
    } else {
        [self.progressHUD hide:YES];
    }
    //这里修改了,为了解决删除文件时候,右滑返回,会在弹窗时候可用
    //self.fd_interactivePopDisabled = NO;
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    //弹出的时候禁用,1.6秒之后启用
    self.fd_interactivePopDisabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    double delayInSeconds = 1.6;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.fd_interactivePopDisabled = NO;
        self.navigationController.navigationBar.userInteractionEnabled = YES;
    });
}

#pragma mark 设置进度条消息
-(void)setProgressMessage:(NSString *)message{
    if (message) {
        if (_progressHUD != nil && !_progressHUD.isHidden) {
            self.progressHUD.labelText = message;
        }
    }
}


#pragma mark 图片列表页面右上角按钮点击事件block
void (^optionButtonClickBlock)(MWPhotoBrowser *) = ^(MWPhotoBrowser *photoBrowser){
    
    NSString * exp = @"解密选中项";
    if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){
        exp = @"导出选中项";
    }
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"导出到相册"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
    }]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除选中项" action:^{
        [photoBrowser.delegate deleteSelected:photoBrowser];
    }]
                                                otherButtonItems:[RIButtonItem itemWithLabel:exp action:^{//导出或解密选择项
        [photoBrowser.delegate exportSelected:photoBrowser];
    }],[RIButtonItem itemWithLabel:@"选择模式" action:^{
        [photoBrowser.delegate photoBrowser:photoBrowser toggleSelectModel:YES];
    }],[RIButtonItem itemWithLabel:@"浏览模式" action:^{
        [photoBrowser.delegate photoBrowser:photoBrowser toggleSelectModel:NO];
    }],[RIButtonItem itemWithLabel:@"全选" action:^{
        [photoBrowser.delegate photoBrowser:photoBrowser toggleSelect:YES];
    }],[RIButtonItem itemWithLabel:@"全不选" action:^{
        [photoBrowser.delegate photoBrowser:photoBrowser toggleSelect:NO];
    }],[RIButtonItem itemWithLabel:@"移动选择项到" action:^{
        if([photoBrowser.currentAlbulName isEqualToString:@"Decrypted"]){//解密(Decrypted)文件夹文件不许移动
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
        }else{//1:导出选中项 2: 导出指定索引
            [photoBrowser.delegate showMove:photoBrowser action:1];
        }
    }],nil];
    [sheet showInView: photoBrowser.view];
};




@end
