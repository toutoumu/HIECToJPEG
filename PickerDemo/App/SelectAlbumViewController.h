//
//  SelectAlbumViewController.h
//  PickerDemo
//
//  Created by LiuBin on 5/1/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#ifndef SelectAlbumViewController_h
#define SelectAlbumViewController_h

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"

@interface SelectAlbumViewController : NBUAssetsLibraryViewController

/// 1:导出选中项 2: 导出指定索引
@property(nonatomic)                               int              action;
@property(nonatomic)                               MWPhotoBrowser   *photoBowser;

@end

#endif