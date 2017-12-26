//
//  AlbumViewController.h
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import <MBProgressHUD/MBProgressHUD.h>

//  相册列表页面,显示所有相册
@interface AlbumViewController : NBUAssetsLibraryViewController <MWPhotoBrowserDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

// Actions
- (IBAction)accessInfo:(id)sender;

@property(nonatomic) MBProgressHUD *progressHUD;

@end
