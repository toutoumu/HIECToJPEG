//
//  TestCell.m
//  XLImageViewerDemo
//
//  Created by Apple on 2017/2/21.
//  Copyright © 2017年 Apple. All rights reserved.
//

#import "ImageCell.h"
#import "UIImageView+WebCache.h"

@interface ImageCell () {
    UIImageView *_imageView;
    UIButton *_selectedButton;
    UIButton *_tapButton;
}
@end

@implementation ImageCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self buildUI];
    }
    return self;
}

- (void)setImageUrl:(NSString *)imageUrl {
    _imageUrl = imageUrl;
    [_imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:[UIImage imageNamed:@"PlaceHolder"]];
    _selectedButton.hidden = !_selectionMode;
    _tapButton.hidden = !_selectionMode;
}

- (void)setPhoto:(NBUFileAsset *)photo {
    _photo = photo;
    _selectedButton.hidden = !_selectionMode;
    _selectedButton.selected = photo.isSelected;
    _tapButton.hidden = !_selectionMode;
    _imageView.image = [UIImage imageWithContentsOfFile:photo.thumbnailImagePath];
}


- (void)buildUI {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.layer.masksToBounds = true;
    [self.contentView addSubview:_imageView];

    // Selection button
    _selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _selectedButton.contentMode = UIViewContentModeTopRight;
    _selectedButton.adjustsImageWhenHighlighted = NO;

    [_selectedButton setImage:[UIImage imageNamed:@"PlaceHolder"] forState:UIControlStateNormal];
    [_selectedButton setImage:[UIImage imageNamed:@"Checkmark"] forState:UIControlStateSelected];

    //S************替换点击事件,并添加双击事件************
    _tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIColor *tintColor = [UIColor colorWithRed:76.0 / 255.0 green:19.0 / 255.0 blue:136.0 / 255.0 alpha:0.0];
    _tapButton.backgroundColor = tintColor;
    _tapButton.frame = _imageView.bounds;
    ////S单击双击事件
    // 单击的 Recognizer
    UITapGestureRecognizer *singleRecognizer;
    singleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(SingleTap:)];
    //点击的次数
    singleRecognizer.numberOfTapsRequired = 1; // 单击
    //给self.view添加一个手势监测；
    [_tapButton addGestureRecognizer:singleRecognizer];

    ////E单击双击事件

    // 调整了图片大小
    _selectedButton.frame = _imageView.bounds;
    _tapButton.hidden = YES;
    //************E替换点击事件,并添加双击事件************

    _selectedButton.hidden = YES;
    [self.contentView addSubview:_selectedButton];
    [self.contentView addSubview:_tapButton];
}


- (void)SingleTap:(UITapGestureRecognizer *)gesture {
    [self selectionButtonPressed];
}

- (void)selectionButtonPressed {
    BOOL selected = !_selectedButton.selected;
    _selectedButton.selected = selected;
    _photo.isSelected = selected;

}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    _photo.isSelected = isSelected;
    _selectedButton.selected = isSelected;
}

- (void)setSelectionMode:(BOOL)selectionMode {
    _selectionMode = selectionMode;
}


@end
