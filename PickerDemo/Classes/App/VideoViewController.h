//
//  VideoViewController.h
//  PickerDemo
//
//  Created by apple on 2017/7/27.
//  Copyright © 2017年 CyberAgent Inc. All rights reserved.
//

#ifndef VideoViewController_h
#define VideoViewController_h

#import <UIKit/UIKit.h>

@interface VideoViewController : NBUCameraViewController

@property(assign, nonatomic) IBOutlet UIButton *shootButton;

@property(assign, nonatomic) IBOutlet UIView *topContainer;

@property(assign, nonatomic) IBOutlet UIView *bottomContainer;

@property(assign, nonatomic) IBOutlet UIView *views;

@property(assign, nonatomic) IBOutlet UILabel *videoData;

@property(assign, nonatomic) IBOutlet UILabel *video;

@property(assign, nonatomic) IBOutlet UILabel *picture;

@end

#endif /* VideoViewController_h */
