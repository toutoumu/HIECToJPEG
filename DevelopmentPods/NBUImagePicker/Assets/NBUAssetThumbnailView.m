//
//  NBUAssetThumbnailView.m
//  NBUImagePicker
//
//  Created by Ernesto Rivera on 2012/11/08.
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

#import "NBUAssetThumbnailView.h"
#import "NBUAssetsGroupViewController.h"

NSString * const NBUAssetThumbnailViewSelectionStateChangedNotification = @"NBUAssetThumbnailViewSelectionStateChangedNotification";

static BOOL _changesAlphaOnSelection;

// 缩略图视图
@implementation NBUAssetThumbnailView

+ (void)initialize
{
    if (self == [NBUAssetThumbnailView class])
    {
        _changesAlphaOnSelection = YES;
    }
}

+ (void)setChangesAlphaOnSelection:(BOOL)yesOrNo
{
    _changesAlphaOnSelection = yesOrNo;
}

+ (BOOL)changesAlphaOnSelection
{
    return _changesAlphaOnSelection;
}

- (void)commonInit
{
    [super commonInit];
    
    // Configure view
    self.targetImageSize = NBUAssetImageSizeThumbnail;
    self.recognizeTap = YES;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    // Update UI
    _selectionView.hidden = selected ? NO : YES;
    if (_changesAlphaOnSelection)
    {
        self.imageView.alpha = selected ? 0.7 : 1.0;
    }
}

- (void)tapped:(id)sender
{
    [super tapped:sender];
    
    self.selected = !_selected;
    
    // Notify selection change
    [[NSNotificationCenter defaultCenter] postNotificationName:NBUAssetThumbnailViewSelectionStateChangedNotification
                                                        object:self];
}

@end

