//
//  NBUAssetsGroupView.h
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
// 相册页面的每一项对应的类
#import <NBUKit/NBUObjectView.h>

@class NBUAssetsGroup;

/**
 Customizable ObjectView used to present a NBUAssetsGroupView object.
 */
@interface NBUAssetsGroupView : NBUObjectView

/// 相册数据 The associated NBUAssetsGroup.
@property (strong, nonatomic, setter=setObject:,
                              getter=object)        NBUAssetsGroup * assetsGroup;

/// @name Outlets

/// 相册名称label An optional group name UILabel.
@property (weak, nonatomic) IBOutlet                UILabel * nameLabel;

/// 文件数label An optional item count UIlabel.
@property (weak, nonatomic) IBOutlet                UILabel * countLabel;

/// 相册封面照片 An optional UIImageView used to display the [NBUAssetsGroup posterImage].
@property (weak, nonatomic) IBOutlet                UIImageView * posterImageView;

/// 是否可以编辑label An optional view to display whether the [NBUAssetsGroup isEditable].
@property (weak, nonatomic) IBOutlet                UIView * editableView;

@end

