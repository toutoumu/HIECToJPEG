//
//  NBUAssetsLibraryViewController.h
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/08/17.
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
/// 相册列表
#import "ScrollViewController.h"

@class ObjectTableView, NBUAssetsGroup, NBUAssetsGroupViewController;

/**
 A simple controller to display a NBUAssetsGroup from the device library.
 
 - Pushes a NBUAssetsLibraryViewController on tap.
 
 */
@interface NBUAssetsLibraryViewController : ScrollViewController
/// 是否只加载沙盒相册
@property(nonatomic)                               BOOL onlyLoadDocument;

/// 排除这些相册不显示
@property(nonatomic)                               NSMutableArray * excludeAlbumNames;

/// 加载相册
- (void)loadGroups;

/// @name Configurable Properties

/// An optional block to handle NBUAssetsGroup selection.
/// @discussion If set, the assetsGroupController won't be pushed automatically.
@property (nonatomic, copy)                         void (^groupSelectedBlock)(NBUAssetsGroup * group);

/// @name Read-only Properties

/// Whether or not the controller is loading assets groups (KVO compliant).
@property (nonatomic, readonly, getter=isLoading)   BOOL loading;

/// The currently retrieved NBUAssetsGroup objects.
@property (strong, nonatomic, readonly)             NSMutableArray * assetsGroups;

/// @name Outlets

/// An ObjectTableView used to display library's NBUAssetsGroup objects.
@property (weak, nonatomic) IBOutlet                ObjectTableView * objectTableView;

/// The assets group controller to be pushed by default.
@property (strong, nonatomic) IBOutlet              NBUAssetsGroupViewController * assetsGroupController;

/// An optional view to be shown (`hidden = NO`) when the user has denied access to the assets library.
@property (strong, nonatomic) IBOutlet              UIView * accessDeniedView;

/// @name Actions

/// Notify controller when a NBUAssetsGroupView has been tapped.
/// @param sender The tapped view.
- (IBAction)assetsGroupViewTapped:(id)sender;

@end

