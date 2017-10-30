//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

@class MWPhotoBrowser;

@protocol MWPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index;
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected;
- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser;

#pragma mark 是否可以退出图片浏览器,如果有选择项,(NO)不可以
- (BOOL)isReturn:(MWPhotoBrowser *)photoBrowser;

/**
 *  切换可选|不可选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true可选|false不可选
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelectModel:(BOOL)select;

/**
 *  设置全选或者取消全选
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param select       true全选|false取消全选
 */
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser toggleSelect:(BOOL)select;

/**
 *  导出选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)exportSelected:(MWPhotoBrowser *)photoBrowser ;

/**
 *  导出指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否导出成功
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser exportAtIndex:(NSUInteger)index;

/**
 *  删除指定索引的图片
 *
 *  @param photoBrowser 图片浏览器引用
 *  @param index        图片索引
 *
 *  @return 是否是否成功
 */
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deleteAtIndex:(NSUInteger)index;


/**
 *  删除选中的图片
 *
 *  @param photoBrowser 图片浏览器引用
 */
- (void)deleteSelected:(MWPhotoBrowser *)photoBrowser;

#pragma mark 弹出移动文件对话框,1:导出选中项 2: 导出指定索引
- (void)showMove:(MWPhotoBrowser *)photoBrowser action:(int) action;

// 移动文件
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser  moveSelectedToAlbum:(NSString *) destAlbumName ;

// 移动当前文件
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser moveAtIndex:(NSUInteger)index toAlbum:(NSString *) destAlbumName ;


@end //End of MWPhotoBrowserDelegate




@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
// 这个值是为了禁用侧滑返回而定义的,由于第三方库没有放到当前目录所以就在这里定义一个一样的变量,让其不报错
@property (nonatomic, assign) BOOL fd_interactivePopDisabled;

@property (nonatomic, weak) IBOutlet id<MWPhotoBrowserDelegate> delegate;
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic) BOOL displayNavArrows;
@property (nonatomic) BOOL displayActionButton;
@property (nonatomic) BOOL displaySelectionButtons;
@property (nonatomic) BOOL alwaysShowControls;
@property (nonatomic) BOOL enableGrid;
@property (nonatomic) BOOL enableSwipeToDismiss;
@property (nonatomic) BOOL startOnGrid;
@property (nonatomic) BOOL autoPlayOnAppear;
@property (nonatomic) NSUInteger delayToHideElements;
@property (nonatomic, readonly) NSUInteger currentIndex;

// Customise image selection icons as they are the only icons with a colour tint
// Icon should be located in the app's main bundle
@property (nonatomic, strong) NSString *customImageSelectedIconName;
@property (nonatomic, strong) NSString *customImageSelectedSmallIconName;
// 当前选中的相册名称
@property (nonatomic, strong) NSString *currentAlbumName;

/// 选项按钮点击--图片列表页面右上角按钮点击事件
@property (nonatomic, copy)   void (^optionButtonClickBlock)(MWPhotoBrowser *);


// Init
- (id)initWithPhotos:(NSArray *)photosArray;
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

- (void)reloadGridData;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;

// Navigation
- (void)showNextPhotoAnimated:(BOOL)animated;
- (void)showPreviousPhotoAnimated:(BOOL)animated;



- (void)showProgressHUDWithMessage:(NSString *)message ;
- (void)hideProgressHUD:(BOOL)animated ;
- (void)showProgressHUDCompleteMessage:(NSString *)message ;
- (void)setProgressMessage:(NSString *)message;

@end
