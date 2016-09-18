//
//  PhotoViewController.h
//  PickerDemo
//
//  Created by LiuBin on 16/1/10.
//  Copyright © 2016年 CyberAgent Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryViewController :  NBUGalleryViewController <UIAlertViewDelegate>//<NBUImageLoader>

//是否有数据更新
@property(nonatomic) BOOL isUpdated;

//删除按钮
@property (strong, nonatomic) IBOutlet UIBarButtonItem * deleteButton;

//导出按钮
@property (strong, nonatomic) IBOutlet UIBarButtonItem * exportButton;

@end
