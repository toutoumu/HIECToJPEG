//
//  NBUGalleryViewController.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2013/04/01.
//  Copyright (c) 2012-2014 CyberAgent Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NBUViewController.h"

@protocol NBUImageLoader, UIButton;

/**
 A controller images from different sources.
 
 - Displays objects from its objectArray using either the default NBUImageLoader
 or a custom imageLoader.
 - Allows pinch and double tap to zoom, toggleFullscreen, toggleThumbnailsView and
 manually setting the currentIndex to be displayed with or without animations.
 - Fully configurable with optional controls such as previousButton, nextButton,
 pageControl, thumbnailsGridView, captionLabel and viewsToHide.
 
 @note The controllers view must be a UIScreenView.
 
 Inspired on FGallery by Grant Davis (https://github.com/gdavis/FGallery-iPhone).
 // 相册界面
 */
@interface NBUGalleryViewController : NBUViewController

/// @name Managing Image Loading

/// The array of objects to be displayed.
/// 需要显示的数据 @see NBUImageLoader.
//@property (strong, nonatomic)               NSArray * objectArray;
@property (strong, nonatomic)               NSMutableArray * objectArray;

/// The gallery views.
@property (nonatomic, readonly)             NSArray * views;

/// An optional custom imageLoader.
/// 用于加载图片的工具类 @discussion If not specified NBUImageLoader will be used.
@property (weak, nonatomic)                 id<NBUImageLoader> imageLoader;

/// The number of images to be preloaded. Default `1`.
@property (nonatomic)                       NSUInteger imagePreloadCount;

/// Force to reconstruct the view hierarchy.
- (void)reloadGallery;

/// @name Managing the Current Image

/// The current index.
/// @discusssion Setting a values is equivalent to setCurrentIndex:animated:
/// 当前显示写照片在集合中的索引 without animation.
@property (nonatomic)                       NSInteger currentIndex;

/// Modify the current index.
/// @param index The desired index.
/// @param animated Whethet to animate the change.
- (void)setCurrentIndex:(NSInteger)index
               animated:(BOOL)animated;

/// Go to the previous index with animation.
/// 上一张 @param sender The sender object.
- (IBAction)goToPrevious:(id)sender;

/// Go to the next index with animation.
/// 下一张 @param sender The sender object.
- (IBAction)goToNext:(id)sender;

/// Refresh the currentIndex based on the pageControl current value.
/// @param sender The sender object.
- (IBAction)pageControlWasTapped:(id)sender;

/// Go to the index corresponding to the tapped NBUGalleryThumbnailView object.
/// @param sender The sender object.
- (IBAction)thumbnailWasTapped:(id)sender;

/// @name Toggling Fullscreen Mode

/// Whether the controller is in fullscreen mode.
/// @discussion In fullscreen mode status and navigation bars are hidden
/// along with any views in the viewsToHide array.
@property (nonatomic, getter=isFulscreen)   BOOL fullscreen;

/// Enter/exit fullscreen mode.
/// @param fullscreen Set to `YES` to go fullscreen.
/// @param animated Whether the mode change should be animated.
- (void)setFullscreen:(BOOL)fullscreen
             animated:(BOOL)animated;

/// Toggle the fullscreen mode.
/// @param sender The sender object.
- (IBAction)toggleFullscreen:(id)sender;

/// @name Toggling Thumbnails

/// Whether to show the thumbnailsGridView;
@property (nonatomic)                       BOOL showThumbnailsView;

/// Show/hide the thumbnailsGridView.
/// @param yesOrNo Whether the thumbnails should be shown.
/// @param animated Whether showing/hiding the view should be animated.
- (void)setShowThumbnailsView:(BOOL)yesOrNo
                     animated:(BOOL)animated;

/// Toggle thumbnailsGridView's visibility.
/// @param sender The sender object.
- (IBAction)toggleThumbnailsView:(id)sender;

/// @name Customizing the Appearance

/// Whether the status and navigation bars should be modified when the
/// controller appears/disappears. Default `YES`.
/// @see navigationBarStyle and statusBarStyle.
@property (nonatomic)                       BOOL updatesBars;

/// The UIStatusBarStyle to be applied to the status bar when the controller
/// appears. Default `UIStatusBarStyleLightContent` on iOS 7 (`UIStatusBarStyleBlackTranslucent` otherwise).
@property (nonatomic)                       UIStatusBarStyle statusBarStyle;

/// The UIBarStyle to be applied to the navigation bar when the controller
/// appears. Default `UIBarStyleBlack` on iOS 7 (`UIStatusBarStyleBlackTranslucent` otherwise).
@property (nonatomic)                       UIBarStyle navigationBarStyle;

/// Whether the the navigation bar should turn translucent when the controller
/// appears (iOS 7 only). Default `YES`.
@property(nonatomic)                        BOOL navigationBarTranslucent;

/// Optional Nib name to be used for objectArray elements.
@property (strong, nonatomic)               NSString * nibNameForViews;

/// The desired space between two images.
@property (nonatomic)                       CGFloat spaceBetweenViews;

/// @name Customizing the Thumbnails

/// 缩略图布局文件 Optional Nib name to be used to display thumbnails.
@property (strong, nonatomic)               NSString * nibNameForThumbnails;

/// 缩略图尺寸 The target thumbnail size.
@property (nonatomic)                       CGSize thumbnailSize;

/// 缩略图间距 The target margin to be applied to thumbnails.
@property (nonatomic)                       CGSize thumbnailMargin;

/// @name Optional Outlets

/// 上一张按钮 Optional previous button.
@property (strong, nonatomic) IBOutlet      id<UIButton> previousButton;

/// 下一张按钮 Optional next button.
@property (strong, nonatomic) IBOutlet      id<UIButton> nextButton;

/// Optional UIPageControl.
@property (weak, nonatomic) IBOutlet      UIPageControl * pageControl;

/// 显示|隐藏缩略图按钮 Optional toggle thumbnails button.
@property (strong, nonatomic) IBOutlet      id<UIButton> toggleThumbnailsViewButton;

/// Optional caption label.
/// @discussion Automatically hidden for images with no caption.
@property (strong, nonatomic) IBOutlet      UILabel * captionLabel;

/// Optional thumbnails view holder.
/// 缩略图列表 @discussion If set to `nil` the thumbnails functionality is disabled.
@property (strong, nonatomic) IBOutlet      UIScrollView * thumbnailsGridView;

/// 切换全屏显示时候,需要显示隐藏的按钮集合(如上一页,下一页) Views that should be shown/hidden when toggling fullscreen.
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray * viewsToHide;

@end

