//
//  NBUAssetsGroupViewController.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/08/01.
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

#import <NBUKit/NBUObjectViewController.h>

@class ObjectGridView, NBUAssetsGroup,NBUAssetThumbnailView,NBUAsset;
@protocol UIButton;

/**
 图片列表
 An extensible controller to display a NBUAssetsGroup's assets as thumbnails.
 
 - Keeps track of selected NBUAssets.
 - Seletected assets can be set programatically.
 - Can be reused with different assets groups.
 */
@interface NBUAssetsGroupViewController : NBUObjectViewController

#pragma mark 图片点击事件
-(void)thumbnailViewSelectionStateChanged:(NSNotification *)notification;

/// @name Configurable Properties

/// 相册信息 The associated NBUAssetsGroup.
@property (strong, nonatomic, setter=setObject:,
                              getter=object)        NBUAssetsGroup * assetsGroup;

/// 顺序反转 Whether to present reverse the assets' order (newest assets on top). Default `NO`.
@property (nonatomic)                               BOOL reverseOrder;

/// 一次加载多少张 The number of assets to be incrementally loaded. Default `100`, set to `0` to load all at once;
@property (nonatomic)                               NSUInteger loadSize;

/// @name Managing Selection

/// 选择的相片列表 The currently selected NBUAsset objects.
@property (strong, nonatomic)                       NSArray * selectedAssets;

/// The currently selectedAssets' URLs.
/// @note For persistence purposes prefer this property over selectedAssets as
/// 选择的相片URL列表 NBUAssets instances may not be unique.
@property (strong, nonatomic)                       NSArray * selectedAssetsURLs;

/// 相片选择改变事件 An optional block to be called when the selection changes.
@property (nonatomic, copy)                         void (^selectionChangedBlock)(NSArray * selectedAssets);

/// 可选择的相片数目 The maximum number of assets that can be selected. Default `0` which means no limit.
@property (nonatomic)                               NSUInteger selectionCountLimit;

/// Whether the controller should clear selection automatically when being presented.
@property (nonatomic)                               BOOL clearsSelectionOnViewWillAppear;

/// @name Read-only Properties

/// Whether or not the controller is loading assets (KVO compliant).
@property (nonatomic, readonly, getter=isLoading)   BOOL loading;

/// The currently retrieved NBUAsset objects.
//@property (strong, nonatomic, readonly)             NSArray * assets;
@property (strong, nonatomic, readonly)             NSMutableArray * assets;

/// @name Outlets

/// 图片网格 An ObjectGridView used to display group's NBUAsset objects.
@property (weak, nonatomic) IBOutlet                ObjectGridView * gridView;

/// An optional UIButton or UIBarButtonItem that will be automatically disabled/enabled as selection changes.
/// 下一步按钮 @discussion You should configure the button's target actions separatly.
@property (weak, nonatomic) IBOutlet                id<UIButton> continueButton;

/// An optional UILabel that will be updated automatically with the associated assetsGroup.
/// 相册名称显示控件 @discussion When set the controllers' [UINavigationItem title] will no longer be modified.
@property (weak, nonatomic) IBOutlet                UILabel * groupNameLabel;

/// 选择的相片数目显示控件 An optional UILabel that will be updated automatically with the assets count.
@property (weak, nonatomic) IBOutlet                UILabel * assetsCountLabel;

@end

