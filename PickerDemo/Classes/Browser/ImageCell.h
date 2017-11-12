//
//  TestCell.h
//  XLImageViewerDemo
//
//  Created by Apple on 2017/2/21.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShowLocalImagesDemoVC;

@interface ImageCell : UICollectionViewCell

@property(nonatomic, weak) ShowLocalImagesDemoVC *gridController;

@property(nonatomic) NSUInteger index;

@property(nonatomic) BOOL selectionMode;

@property(nonatomic) BOOL isSelected;

@property(nonatomic, copy) NSString *imageUrl;

@property(nonatomic, copy) NBUFileAsset *photo;

@end
