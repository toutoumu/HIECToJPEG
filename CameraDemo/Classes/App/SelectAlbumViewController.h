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

/// 1:移动选中项 2: 移动指定索引
@property(nonatomic) int action;
@property(nonatomic) MWPhotoBrowser *photoBrowser;

@end

#endif
