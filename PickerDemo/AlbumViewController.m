// 相册列表,图片列表,图片浏览
#import "AlbumViewController.h"
#import "TTFIleUtils.h"
#import "PhotosViewController.h"
#import "MWPhotoBrowser.h"
#import "TTFIleUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SelectAlbumViewController.h"
// 相册列表,图片列表,图片浏览
@interface AlbumViewController ()
{
    BOOL _isUpdated;// 相册数据,是否已经更新,如果已经更新那么需要重新加载数据
    NSMutableArray *_selections;// 与图片数据集合一一对应,是否选中
    NSMutableArray * _asses;// 图片数据集合
    NBUAssetsGroup * _group;// 当前相册引用
}

@end
// 相册列表,图片列表,图片浏览
@implementation AlbumViewController

// 类初始化
+(void)initialize
{
    if (self == [AlbumViewController class])
    {
        // 创建被删除文件相册
        [TTFIleUtils createAlbum:@"Deleted"];
        [TTFIleUtils createAlbum:@"Beauty"];

        // 注册沙盒相册
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *array = [TTFIleUtils getAllAlbums];
        for (int i = 0; i< [array count]; i++) {
            NSURL *url = [NSURL URLWithString:[documentsDirectory stringByAppendingPathComponent:[array objectAtIndex:i]]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupforURL:url name: [array objectAtIndex:i]];
        }
    }
}

// 对象初始化
- (void)setUp
{
    _isUpdated = NO;
    _selections = [NSMutableArray new];
    _asses = [[NSMutableArray alloc]init];
    _group = nil;
}

#pragma mark - 生命周期方法
- (void)viewDidLoad
{
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
    // 设置相册点击事件, 设置了之后上面的图片列表将会失效
    self.groupSelectedBlock = ^(NBUAssetsGroup * group){
        if (group) {
            _group = group;
            MWPhotoBrowser *_browser = [[MWPhotoBrowser alloc] initWithDelegate:weakSelf];
            _browser.displayActionButton = YES;//分享按钮
            _browser.displayNavArrows = YES;//翻页箭头
            _browser.displaySelectionButtons = NO;//是否显示选择按钮
            _browser.alwaysShowControls = NO;//是否总是显示底部工具条
            _browser.zoomPhotosToFill = YES;
            _browser.enableGrid = YES;//启用网格列表
            _browser.startOnGrid = YES;//从网格列表显示
            _browser.enableSwipeToDismiss = YES;
            _browser.autoPlayOnAppear = NO;
            _browser.currentAlbulName = group.name;//当前相册名称
            _browser.optionButtonClickBlock = optionButtonClickBlock;//图片列表页面右上角按钮点击事件block
            [_browser setCurrentPhotoIndex:0];
            
            // 异步加载数据
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [group assetsWithTypes:NBUAssetTypeAny
                             atIndexes:nil
                          reverseOrder:YES
                   incrementalLoadSize:0
                           resultBlock:^(NSArray * assets,
                                         BOOL finished,
                                         NSError * error){
                               if (!error){
                                   // 更新数据
                                   _asses = (NSMutableArray *) assets;
                                   // 重置选中集合 Reset selections
                                   if (finished) {
                                       [weakSelections removeAllObjects];
                                       for (int i = 0; i < _asses.count; i++) {
                                           [weakSelections addObject:[NSNumber numberWithBool:NO]];
                                       }
                                   }
                                   
                                   // Update grid view and selected assets on main thread
                                   dispatch_async(dispatch_get_main_queue(), ^ {
                                       if (YES) {// 跳转到相片列表页面
                                           [weakSelf.navigationController pushViewController:_browser animated:YES];
                                       } else {//弹出相片列表对话框
                                           UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:_browser];
                                           nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                                           [weakSelf presentViewController:nc animated:YES completion:nil];
                                       }
                                       
                                   });
                               }
                           }];
            });
        }
    };
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // 显示标题栏
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    if (_isUpdated) {//如果数据有更新
        _isUpdated = NO;
        [self loadGroups];
    }
    
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
    
    // Authorized?
    if (![NBUAssetsLibrary sharedLibrary].userDeniedAccess)
    {
        // No need for info button
        self.navigationItem.rightBarButtonItem = nil;
    }
}



#pragma mark - 图片浏览器协议实现 MWPhotoBrowserDelegate
/**
 *  图片数量
 *
 *  @param photoBrowser 图片浏览器引用
 *
 *  @return 图片数量
 */
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
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count){
        NBUAsset * data = [_asses objectAtIndex:index];
        ALAsset *asset = data.ALAsset;
        if (asset) {//8.x以下系统,如果是访问相册图片那么使用url可以异步加载
            MWPhoto *photo = [MWPhoto photoWithURL: asset.defaultRepresentation.url];
            if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                photo.videoURL = asset.defaultRepresentation.url;
            }
            
            return photo;
        }
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return[MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset fullScreenSize]];
        }
        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        return [MWPhoto photoWithImage: data.fullScreenImage];
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
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (_asses && _asses.count > 0 && index < _asses.count){
        NBUAsset * data = [_asses objectAtIndex:index];
        ALAsset *asset = data.ALAsset;
        if (asset) {//8.x以下系统,如果是访问相册图片那么使用url可以异步加载
            MWPhoto *photo = [MWPhoto photoWithURL: asset.defaultRepresentation.url];
            if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                photo.videoURL = asset.defaultRepresentation.url;
            }
            
            return photo;
        }
        PHAsset *phAsset = data.PHAsset;
        if (phAsset) {//8.x以上系统,如果是访问相册图片那么使用url可以异步加载
            //注意这里不需要判断是否为视频,初始化方法里面会判断
            return[MWPhoto photoWithAsset:phAsset targetSize:[NBUAsset thumbnailSize]];
        }
        // 如果是访问沙盒(document目录)中的图片那么直接返回图片
        return [MWPhoto photoWithImage: data.thumbnailImage];
    }
    return nil;
    
    /*if (_asses && _asses.count > 0 && index < _asses.count){
        NBUAsset * data = [_asses objectAtIndex:index];
        MWPhoto *thumb = [MWPhoto photoWithImage: data.thumbnailImage];
        if (data.ALAsset) {//如果是系统相册数据
            if ([data.ALAsset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                thumb.isVideo = true;
            }
        }
        return thumb;
    }
    return nil;*/
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

/**
 *  点击分享操作按钮后的回调,如果设置了这个那么默认的将不会显示 [单张图片右下角的按钮]
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    void (^deleteBlock)( ) = ^(){// 删除
        [photoBrowser.delegate photoBrowser:photoBrowser deleteAtIndex:index];
    };
    void (^exportBlock)( ) = ^(){// 导出
        [photoBrowser.delegate photoBrowser:photoBrowser exportAtIndex:index];
    };
    
    void (^move)() = ^(){// 移动
        if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
            [photoBrowser showProgressHUDWithMessage:@""];
            [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
            return ;
        }
        
        SelectAlbumViewController *controll = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectAlbumViewController"];
        controll.onlyLoadDocument = YES;// 只加载沙盒
        // 排除当前相册和Deleted相册
        controll.action = 2;//移动指定索引
        controll.photoBowser = photoBrowser;
        controll.excludeAlbumNames = [[NSMutableArray alloc]init];
        [controll.excludeAlbumNames insertObject:photoBrowser.currentAlbulName atIndex:0];
        [controll.excludeAlbumNames insertObject:@"Deleted" atIndex:0];
        [self.navigationController pushViewController:controll animated:YES];
    };
    
    
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"导出到相册"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock]
                                                otherButtonItems:
                             [RIButtonItem itemWithLabel:@"导出" action:exportBlock],
                             [RIButtonItem itemWithLabel:@"移动" action:move],nil];
    [sheet showInView:photoBrowser.view];
    NSLog(@"ACTION!");
}

/**
 *  第index张图片将要显示
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
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
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
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
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

/**
 *  模态窗口呈现完成之后的回调
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - 图片浏览器协议实现 MWPhotoBrowserDelegate 文件操作相关
/**
 *  切换可选|不可选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true可选|false不可选
 */
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelectModel:(BOOL)select{
    if (photoBrowser.displaySelectionButtons != select) {
        photoBrowser.displaySelectionButtons = select;
        [photoBrowser reloadGridData];
    }
}
/**
 *  设置全选或者取消全选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true全选|false取消全选
 */
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelect:(BOOL)select{
    [_selections removeAllObjects];
    if (select) {
        photoBrowser.displaySelectionButtons = YES;
    }
    NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
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
-(void)exportSelected:(MWPhotoBrowser *)photoBrowser{
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能导出"];
        return ;
    }
    void (^exportBlock)( ) = ^(){
        [photoBrowser showProgressHUDWithMessage:@""];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *selectedAssets = [[NSMutableArray alloc]init];
            if (_selections != nil && _selections.count > 0) {
                for (int i = 0; i < _selections.count; i++) {
                    if ([[_selections objectAtIndex:i] boolValue]) {
                        NBUAsset *asset =  [_asses objectAtIndex:i];
                        [selectedAssets addObject:asset];
                    }
                }
            }
            
            // 如果有可以导出的文件
            if (selectedAssets.count > 0) {
                [self export:selectedAssets atIndex:0 photoBrowser:photoBrowser];
            }
            // 如果没有可以导出的文件
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage:@"请选择要导出的文件"];
                });
            }
        });
    };
    
    // 执行导出操作
    [[[UIAlertView alloc] initWithTitle:@"警告"
                                message:@"确定要导出?"
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil] show];
}

/**
 *  导出指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否导出成功
 */
-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser exportAtIndex:(NSUInteger)index{
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能导出"];
        return true;
    }
    //void (^exportBlock)( ) = ^(){
    if (_asses == nil || _asses.count == 0) return YES;// 如果没有数据
    NBUAsset *asset = [_asses objectAtIndex:index];
    if (asset == nil) return YES;// 如果当前项为空
    
    [photoBrowser showProgressHUDWithMessage:@"正在导出..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll: [TTFIleUtils fixOrientation:asset.fullResolutionImage]
                                                       metadata:nil
                                       addToAssetsGroupWithName:@"test"
                                                    resultBlock:^(NSURL * assetURL, NSError * error){
                                                        dispatch_async(dispatch_get_main_queue(), ^ {
                                                            if (!error) {
                                                                [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
                                                                _isUpdated = YES;
                                                            }else{
                                                                [photoBrowser showProgressHUDCompleteMessage:@"导出失败"];
                                                            }
                                                        });
                                                    }];
    });
    
    // };
    /*[[[UIAlertView alloc] initWithTitle:@"警告"
     message:@"确定要导出?"
     cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
     otherButtonItems:[RIButtonItem itemWithLabel:@"导出" action:exportBlock], nil] show];*/
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
-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deleteAtIndex:(NSUInteger)index{
    void (^deleteBlock)() = ^(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (_asses == nil || _asses.count == 0) return ;// 如果没有数据
            NBUAsset *asset = [_asses objectAtIndex:index];
            if (asset == nil) return ;// 如果当前项为空
            
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@"删除..."];
                if (!asset.isEditable) {
                    [photoBrowser showProgressHUDCompleteMessage:@"不能删除"];
                }
            });
            
            // 如果是document文件且不是Deleted相册,移动文件到已删除文件夹
            if([asset isMemberOfClass:[NBUFileAsset class]] && ![photoBrowser.currentAlbulName isEqualToString:@"Deleted"]){
                NBUFileAsset *temp = (NBUFileAsset *)asset;
                BOOL b = [TTFIleUtils moveFile:temp from:photoBrowser.currentAlbulName toAlbum:@"Deleted"];
                if (b) {
                    _isUpdated = YES;
                    [_selections removeObjectAtIndex:index];
                    [_asses removeObjectAtIndex:index];
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [photoBrowser reloadData];
                        if(_asses.count == 0){//全部移动完成才刷新这个否则会有bug
                            [photoBrowser reloadGridData];
                        }
                        [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
                    });
                    
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [photoBrowser showProgressHUDCompleteMessage:@"删除失败"];
                    });
                }
            }else{
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
                        }
                        
                        
                    });
                }];
            }
            
        });
    };
    
    // 如果是沙盒文件
    if([_group isMemberOfClass:[NBUDirectoryAssetsGroup class]]){
        deleteBlock();
    }else{
        [[[UIAlertView alloc] initWithTitle:@"警告"
                                    message:@"确定要删除?"
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                           otherButtonItems:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock], nil] show];}
    return YES;
}

#pragma mark 删除选中的图片
/**
 *  删除选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
-(void)deleteSelected:(MWPhotoBrowser *)photoBrowser{
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
            // 如果有可以删除的文件
            if (removedArray.count > 0) {//递归删除
                [self delete:removedArray atIndex:0 photoBrowser:photoBrowser];
            }
            // 如果没有可以删除的文件
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage:@"请选择要删除的文件"];
                });
            }
        });
    };
    
    [[[UIAlertView alloc] initWithTitle:@"警告"
                                message:@"确定要删除?"
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"删除" action:deleteBlock], nil] show];
}

#pragma mark 点击返回按钮是否退出图片浏览器
-(BOOL)isReturn:(MWPhotoBrowser *)photoBrowser {
    if (_selections != nil && _selections.count > 0) {
        // 获取选中项中可以删除的文件
        for (int i = 0; i < _selections.count; i++) {
            if ([[_selections objectAtIndex:i] boolValue]) {
                return NO;
            }
        }
    }
    return YES;
}


#pragma mark 网格列表页面,显示移动对话框
- (void)showMove:(MWPhotoBrowser *)photoBrowser{
    if (![_group isMemberOfClass: [NBUDirectoryAssetsGroup class]]) {
        [photoBrowser showProgressHUDWithMessage:@""];
        [photoBrowser showProgressHUDCompleteMessage:@"该相册文件不能移动"];
        return ;
    }
    
    SelectAlbumViewController *controll = [self.storyboard instantiateViewControllerWithIdentifier:@"SelectAlbumViewController"];
    controll.onlyLoadDocument = YES;// 只加载沙盒
    // 排除当前相册和Deleted相册
    controll.action = 1;// 导出选中项
    controll.photoBowser = photoBrowser;
    controll.excludeAlbumNames = [[NSMutableArray alloc]init];
    [controll.excludeAlbumNames insertObject:photoBrowser.currentAlbulName atIndex:0];
    [controll.excludeAlbumNames insertObject:@"Deleted" atIndex:0];
    [self.navigationController pushViewController:controll animated:YES];
}


#pragma mark 移动选择的文件
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser  moveSelectedToAlbum:(NSString *) destAlbumName {
    void (^move)() = ^(){// 移动
        [photoBrowser showProgressHUDWithMessage:@"正在移动"];
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *movedArray = [[NSMutableArray alloc] init];
            if (_selections != nil && _selections.count > 0) {
                // 获取选中项中可以删除的文件
                for (int i = 0; i < _selections.count; i++) {
                    if ([[_selections objectAtIndex:i] boolValue]) {
                        NBUAsset *asset =  [_asses objectAtIndex:i];
                        if (asset.isEditable) {
                            [movedArray addObject:asset];
                        }
                    }
                }
            }
            // 如果有可以移动的文件
            if (movedArray.count > 0) {
                //移动
                for (int i = 0; i < movedArray.count; i++) {
                    // 如果不是最后一项
                    NBUAsset * asset = [movedArray objectAtIndex:i];
                    // 如果是document文件且不是Deleted相册,移动文件到已删除文件夹
                    if([asset isMemberOfClass:[NBUFileAsset class]]){
                        BOOL b = [TTFIleUtils moveFile:(NBUFileAsset *)asset from:photoBrowser.currentAlbulName toAlbum:destAlbumName];
                        _isUpdated = YES;
                        if (b) {
                            [_asses removeObject:asset];
                        }else{ // 部分删除失败
                            dispatch_async(dispatch_get_main_queue(), ^ {
                                [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                            });
                            break;
                        }
                    }
                }
                // 重置选中项数据
                [_selections removeAllObjects];
                NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
                for (int i = 0; i < count; i++) {
                    [_selections addObject:[NSNumber numberWithBool:NO]];
                }
                dispatch_async(dispatch_get_main_queue(), ^ {
                    // 刷新数据
                    [photoBrowser reloadData];
                    [photoBrowser reloadGridData];
                    [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
                });
            }
            // 如果没有可以删除的文件
            else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage:@"请选择要移动的文件"];
                });
            }
        });
    };
    
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"选择操作"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动" action:move]
                                                otherButtonItems:nil];
    [sheet showInView:photoBrowser.view];
}

#pragma mark 移动当前项
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser moveAtIndex:(NSUInteger)index toAlbum:(NSString *) destAlbumName {
    void (^move)() = ^(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (_asses == nil) {
                return ;
            }
            
            NBUAsset *asset = [_asses objectAtIndex:index];
            if (asset ==nil) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDWithMessage:@""];
                if (![asset isMemberOfClass:[NBUFileAsset class]]) {
                    [photoBrowser showProgressHUDCompleteMessage:@"不能移动"];
                }
            });
            NBUFileAsset *temp = (NBUFileAsset *)asset;
            BOOL b = [TTFIleUtils moveFile:temp from:photoBrowser.currentAlbulName toAlbum:destAlbumName];
            if (b) {
                _isUpdated = YES;
                [_selections removeObjectAtIndex:index];
                [_asses removeObjectAtIndex:index];
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser reloadData];
                    [photoBrowser showProgressHUDCompleteMessage:@"移动成功"];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser showProgressHUDCompleteMessage:@"移动失败"];
                });
            }
        });
    };
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"选择操作"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"移动" action:move]
                                                otherButtonItems:nil];
    [sheet showInView:photoBrowser.view];
    return YES;
}


#pragma mark - ------私有方法

#pragma mark 递归导出
/**
 *  递归导出照片
 *
 *  @param data         照片数据
 *  @param index        当前要导出的相片的索引
 *  @param photoBrowser 图片浏览器引用
 */
-(void)export:(NSArray * )data atIndex :(int)index photoBrowser :(MWPhotoBrowser *)photoBrowser{
    // 如果已经循环到最后一项
    if (index < 0 || index > data.count -1) {
        if(index == data.count){
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser showProgressHUDCompleteMessage:@"导出成功"];
            });
        }
        return;
    }
    
    NBUAsset * asset = [data objectAtIndex:index];
    [[NBUAssetsLibrary sharedLibrary] saveImageToCameraRoll: [TTFIleUtils fixOrientation:asset.fullResolutionImage]
                                                   metadata:nil
                                   addToAssetsGroupWithName:@"test"
                                                resultBlock:^(NSURL * assetURL,
                                                              NSError * saveError)
     {
         NSString *message = [NSString stringWithFormat:@"%d/%lu", index + 1, (unsigned long)data.count];
         [photoBrowser setProgressMessage:message];
         _isUpdated = YES;
         if (saveError == nil) {
             [self export:data atIndex:index + 1 photoBrowser:photoBrowser];
         }else{
             dispatch_async(dispatch_get_main_queue(), ^ {
                 [photoBrowser showProgressHUDCompleteMessage:@"部分导出成功"];
             });
         }
     }];
}


#pragma mark 递归删除
/**
 *  递归删除照片
 *
 *  @param data         照片数据
 *  @param index        当前要删除的相片的索引
 *  @param photoBrowser 图片浏览器引用
 */
-(void)delete:(NSArray * )data atIndex :(int)index photoBrowser :(MWPhotoBrowser *)photoBrowser{
    // 如果已经循环到最后一项
    if (index < 0 || index >= data.count) {
        if(index == data.count){// 如果已经循环到最后一项
            // 重置选中项数据
            [_selections removeAllObjects];
            NSUInteger count = [self numberOfPhotosInPhotoBrowser:photoBrowser];
            for (int i = 0; i < count; i++) {
                [_selections addObject:[NSNumber numberWithBool:NO]];
            }
            dispatch_async(dispatch_get_main_queue(), ^ {
                // 刷新数据
                [photoBrowser reloadData];
                [photoBrowser reloadGridData];
                [photoBrowser showProgressHUDCompleteMessage:@"删除成功"];
            });
        }
        return;
    }
    // 如果不是最后一项
    NBUAsset * asset = [data objectAtIndex:index];
    // 如果是document文件且不是Deleted相册,移动文件到已删除文件夹
    if([asset isMemberOfClass:[NBUFileAsset class]] && ![photoBrowser.currentAlbulName isEqualToString:@"Deleted"]){
        BOOL b = [TTFIleUtils moveFile:(NBUFileAsset *)asset from:photoBrowser.currentAlbulName toAlbum:@"Deleted"];
        _isUpdated = YES;
        if (b) {
            [_asses removeObject:asset];
            [self delete:data atIndex:index + 1 photoBrowser:photoBrowser];
        }else{ // 部分删除失败
            dispatch_async(dispatch_get_main_queue(), ^ {
                [photoBrowser hideProgressHUD:YES];
            });
        }
    }else {
        [asset delete:^(NSError *error, BOOL success) {
            _isUpdated = YES;
            if (error == nil ) {
                [_asses removeObject:asset];
                [self delete:data atIndex:index + 1 photoBrowser:photoBrowser];
            }else{ // 部分删除失败
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [photoBrowser hideProgressHUD:YES];
                });
            }
        }];
    }
}


#pragma mark 权限验证 Handling access authorization
- (void)accessInfo:(id)sender{
    // 如果用户不允许访问 User denied access?
    if ([NBUAssetsLibrary sharedLibrary].userDeniedAccess){
        [[[UIAlertView alloc] initWithTitle:@"Access denied"
                                    message:@"Please go to Settings:Privacy:Photos to enable library access" delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    // 如果设置不允许访问 Parental controls
    if ([NBUAssetsLibrary sharedLibrary].restrictedAccess){
        [[[UIAlertView alloc] initWithTitle:@"Parental restrictions"
                                    message:@"Please go to Settings:General:Restrictions to enable library access" delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

#pragma mark 图片列表页面右上角按钮点击事件block
void (^optionButtonClickBlock)(MWPhotoBrowser *) = ^(MWPhotoBrowser *photoBrowser){
    
    
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"导出到相册"
                                                cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{}]
                                           destructiveButtonItem:[RIButtonItem itemWithLabel:@"删除选中项" action:^{
        [photoBrowser.delegate deleteSelected:photoBrowser];
    }]
                                                otherButtonItems:[RIButtonItem itemWithLabel:@"导出选中项" action:^{
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
        [photoBrowser.delegate showMove:photoBrowser];
    }],nil];
    [sheet showInView: photoBrowser.view];
};


  

@end
