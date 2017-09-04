//
//  PhotosViewController.h
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

@interface PhotosViewController : NBUAssetsGroupViewController <UIActionSheetDelegate,UIAlertViewDelegate>

//是否需要数据更新 , 如果当前页面数据变更那么isUpdate = YES
@property(nonatomic) BOOL isUpdated;
//相册页面
@property (strong, nonatomic) IBOutlet NBUGalleryViewController *galleryViewController;
//编辑按钮
@property (strong, nonatomic) IBOutlet UIBarButtonItem * editButton;

@end
