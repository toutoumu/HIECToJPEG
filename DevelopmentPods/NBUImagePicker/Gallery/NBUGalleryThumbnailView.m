//
//  NBUGalleryThumbnailView.m
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2013/04/17.
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

#import "NBUGalleryThumbnailView.h"
#import "NBUImagePickerPrivate.h"
// 缩略图 显示用的视图,可以由自己配置
@implementation NBUGalleryThumbnailView

@dynamic viewController;

- (void)commonInit
{
    [super commonInit];
    
    self.recognizeTap = YES;
}

/**
 *  缩略图点击事件
 *
 *  @param sender 缩略图视图
 */
- (void)tapped:(id)sender
{
    [super tapped:sender];
    
    [self.viewController thumbnailWasTapped:self];
}

@end

