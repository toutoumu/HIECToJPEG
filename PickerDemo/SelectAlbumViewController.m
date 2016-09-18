//
//  SelectAlbumViewController.m
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import "SelectAlbumViewController.h"
#import "TTFIleUtils.h"
#import "PhotosViewController.h"
#import "MWPhotoBrowser.h"
#import "AlbumViewController.h"
#import "TTFIleUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation SelectAlbumViewController

+(void)initialize
{
    if (self == [SelectAlbumViewController class])
    {
        // 注册沙盒相册
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *array = [TTFIleUtils getAllAlbums];
        for (int i = 0; i< [array count]; i++) {
            NSURL *url = [NSURL URLWithString:[documentsDirectory stringByAppendingPathComponent:[array objectAtIndex:i]]];
            [[NBUAssetsLibrary sharedLibrary] registerDirectoryGroupforURL:url name: [array objectAtIndex:i]];
        }
    }
}

#pragma mark - 生命周期方法

- (void)viewDidLoad
{
    // 只加载沙盒相册,必须在 [super viewDidLoad];之前才有效
    self.onlyLoadDocument = YES;
    
    [super viewDidLoad];
    
     // 相册列表每一项的布局文件 Configure grid view
    self.objectTableView.nibNameForViews = @"CustomAssetsGroupView";
    
    // 下一个页面返回按钮标题,图片列表页面返回按钮的名称 Customization
    self.customBackButtonTitle = @"Cancel";
    
    __weak SelectAlbumViewController * weakSelf = self;
    __weak MWPhotoBrowser * weakPhotoBrowser = _photoBowser;
       // 设置相册点击事件, 设置了之后上面的图片列表将会失效
    self.groupSelectedBlock = ^(NBUAssetsGroup * group){
        if (group) {
            // 移动照片
              if (_action == 1) {
                [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveSelectedToAlbum:group.name] ;
            }else if(_action == 2){
                [weakPhotoBrowser.delegate photoBrowser:weakPhotoBrowser moveAtIndex:weakPhotoBrowser.currentIndex toAlbum:group.name];
            }
            [weakSelf.navigationController popViewController:weakSelf];
        }
    };
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // 获取前一项(UIViewcontrol)因为是count所以,减一是代表自己,减二代表前一个页面 We're not first so show back button
    UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
     UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:nil action:nil];
    // Appearance
    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
    [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
    [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
    previousViewController.navigationItem.backBarButtonItem = newBackButton;
    
    // 显示标题栏
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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

@end
