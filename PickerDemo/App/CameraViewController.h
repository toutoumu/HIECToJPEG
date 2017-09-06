//
//  ViewController.h
//  PickerDemo
//
//  Created by LiuBin on 1/14/16.
//  Copyright © 2016 CyberAgent Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPPinPadViewController.h"

#pragma mark 照片拍摄界面, 实现 PinPadPasswordProtocol 协议

@interface CameraViewController : NBUCameraViewController <PinPadPasswordProtocol>

#pragma mark 图片保存到的相册名称, 设置这个名称的同时会创建相应的文件目录, 默认值为@"Album"
@property(assign, nonatomic) NSString *albumName;

#pragma mark 拍摄按钮, 第一次点击操作是设置相机参数
@property(assign, nonatomic) IBOutlet UIButton *shootButton;

#pragma mark 打开相册按钮
@property(assign, nonatomic) IBOutlet UIButton *openAlbumBtn;

#pragma mark 震动相关

void AudioServicesPlaySystemSoundWithVibration(int, id, id);
@end
