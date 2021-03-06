//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <DACircularProgress/DACircularProgressView.h>
#import "MWCommon.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "MWPhotoBrowserPrivate.h"
#import "UIImage+MWPhotoBrowser.h"

// Private methods and properties
@interface MWZoomingScrollView () {

    MWPhotoBrowser __weak *_photoBrowser;
    UIScrollView __weak *_parentView;
    UIView  __weak *_container;

    MWTapDetectingView *_tapView; // for background taps
    MWTapDetectingImageView *_photoImageView;
    DACircularProgressView *_loadingIndicator;
    UIImageView *_loadingError;

}

@end

@implementation MWZoomingScrollView

/**
 *
 * @param browser
 * @param parentView 当前View的父视图 _pagingScrollView
 * @param container parentView 的父视图
 * @return
 */
- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser parent:(UIScrollView *)parentView container:(UIView *)container; {
    if ((self = [super init])) {

        // Setup
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        _parentView = parentView;
        _container = container;

        // Tap view for background
        _tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
        _tapView.tapDelegate = self;
        _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tapView.backgroundColor = [UIColor blackColor];
        [self addSubview:_tapView];

        // Image view
        _photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
        _photoImageView.contentMode = UIViewContentModeCenter;
        //_photoImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        [self addSubview:_photoImageView];

        // Loading indicator
        _loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        _loadingIndicator.userInteractionEnabled = NO;
        _loadingIndicator.thicknessRatio = 0.1;
        _loadingIndicator.roundedCorners = NO;
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_loadingIndicator];

        // Listen progress notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:MWPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];

        // Setup
        self.delegate = self;
        self.scrollsToTop = NO;//点击状态栏不让其滚动到顶部
        //self.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (@available(iOS 11.0, *)) {//解决ios11,图片放大后点击图片会造成图片偏移
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self.panGestureRecognizer addTarget:self action:@selector(scrollViewPanMethod:)];

    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_photoImageView];
    //_beginPoint = point;
}

- (void)scrollViewPanMethod:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (self.zoomScale != self.minimumZoomScale) {//如果手动进行了缩放
        //NSLog(@"跳过了 %d", panGestureRecognizer.state);
        //如果触发了拖动操作,但是由于某种原因(缩放改变,翻页)不能继续完成拖放操作,将状态还原
        if (_parentView.isHidden /*&& (panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled)*/) {
            //NSLog(@"滑动取消还原 %d", panGestureRecognizer.state);
            _parentView.scrollEnabled = YES;
            _parentView.hidden = NO;
            _photoBrowser.coverImage.hidden = YES;
            _photoBrowser.backGroundView.hidden = YES;
        }
        return;
    }
    static CGFloat sx;
    static CGFloat sy;
    static CGSize imageSize;
    static CGPoint imageOrigin;
    static CGFloat minPanLength = 150.0f;//最小拖拽返回相应距离
    static CGFloat minPanLengthScale = 350.0f;//最小拖拽返回相应距离
    switch (panGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            //NSLog(@"拖拽-----开始 %f %f", self.zoomScale, self.minimumZoomScale);

            // 这里取值为图片的大小
            imageSize = _photoImageView.frame.size;
            imageOrigin = _photoImageView.frame.origin;

            // 计算偏移比例,locationInView 根据缩放得到正确的值
            CGPoint beginningLocation = [panGestureRecognizer locationInView:_photoImageView];
            sx = beginningLocation.x * self.zoomScale / imageSize.width;
            sy = beginningLocation.y * self.zoomScale / imageSize.height;

            _parentView.hidden = YES;
            _photoBrowser.coverImage.hidden = NO;
            _photoBrowser.backGroundView.hidden = NO;

            _photoBrowser.backGroundView.alpha = 1.0f;

            _photoBrowser.coverImage.frame = _photoImageView.frame;
            _photoBrowser.coverImage.image = _photoImageView.image;
            _photoBrowser.coverImage.contentMode = UIViewContentModeScaleToFill;
            if (_photoBrowser.coverImage.image == nil) {
                _photoBrowser.coverImage.tag = _index;//设置tag让大图加载完成之后能够找到对应的图片加载
                //如果大图没有加载,先加载缩略图,当图片加载完成之后替换为大图,见方法 handleMWPhotoLoadingDidEndNotification
                _photoBrowser.coverImage.image = [_photoBrowser imageForPhoto:[_photoBrowser thumbPhotoAtIndex:_index]];
                //如果没加载大图(此时的frame是全屏)图片保持比例,内容全部显示,内容缩放以适应屏幕。其余部分是透明的
                _photoBrowser.coverImage.contentMode = UIViewContentModeScaleAspectFit;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [panGestureRecognizer translationInView:self];
            //NSLog(@"拖拽-----改变 x: %f / y: %f", translation.x, translation.y);

            // 背景透明度
            CGFloat alpha = 1.0f - ABS(translation.y) / minPanLength;
            // CGFloat alpha = 1.0f - MAX(ABS(translation.x), ABS(translation.y)) / minPanLengthScale;
            CGFloat scale = 1.0f - ABS(translation.y) / minPanLengthScale;
            if (scale < 0.7) scale = 0.7;
            if (alpha < 0) alpha = 0;
            _photoBrowser.backGroundView.alpha = alpha;

            // 改变图片的布局
            CGRect coverFrame;
            // 图片的尺寸
            coverFrame.size.width = imageSize.width * scale;
            coverFrame.size.height = imageSize.height * scale;
            // 图片的位置, 原来位置 + 偏移值 + 缩放导致的偏移值 + (宽度|高度变化*比例系数)
            coverFrame.origin.x = imageOrigin.x + translation.x + (imageSize.width - coverFrame.size.width) * sx;
            coverFrame.origin.y = imageOrigin.y + translation.y + (imageSize.height - coverFrame.size.height) * sy;
            _photoBrowser.coverImage.frame = coverFrame;

            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGPoint translation = [panGestureRecognizer translationInView:self];
            CGPoint velocity = [panGestureRecognizer velocityInView:self];
            //NSLog(@"拖拽-----结束%f", velocity.y);
            if (ABS(translation.y) < minPanLength && ABS(velocity.y) < 50) {//还原
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     _photoBrowser.backGroundView.alpha = 1.0f;
                                     _photoBrowser.coverImage.frame = _photoImageView.frame;

                                 }
                                 completion:^(BOOL finished) {
                                     _parentView.hidden = NO;
                                     _photoBrowser.coverImage.hidden = YES;
                                     _photoBrowser.backGroundView.hidden = YES;
                                 }];
            } else {// 退出图片浏览
                [_photoBrowser showGrid:NO];
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     _photoBrowser.backGroundView.alpha = 0.0f;

                                     UICollectionViewCell *cell = _photoBrowser.currentGridCell;
                                     if (cell != nil) {// 移动到单元格所在位置
                                         _photoBrowser.coverImage.frame = [cell convertRect:cell.bounds toCoordinateSpace:_container];
                                     } else {
                                         CGRect frame = _photoBrowser.coverImage.frame;
                                         if (frame.origin.y > 0) {//根据偏移的方向判断从上还是下退出
                                             frame.origin.y = _container.frame.size.height;
                                         } else {
                                             frame.origin.y = -_container.frame.size.height;
                                         }
                                         _photoBrowser.coverImage.frame = frame;
                                     }
                                 }
                                 completion:^(BOOL finished) {
                                     _parentView.hidden = NO;
                                     _photoBrowser.coverImage.hidden = YES;
                                     _photoBrowser.backGroundView.hidden = YES;
                                 }];
            }
            break;
        }
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            //NSLog(@"拖拽-----失败,取消");
            // 拖拽未知情况,还原所有设置
            _parentView.scrollEnabled = YES;
            _parentView.hidden = NO;
            _photoBrowser.coverImage.hidden = YES;
            _photoBrowser.backGroundView.hidden = YES;
            break;
        }
    }
}


- (void)dealloc {
    if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [_photo cancelAnyLoading];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [self hideImageFailure];
    self.photo = nil;
    self.captionView = nil;
    self.selectedButton = nil;
    self.playButton = nil;
    _photoImageView.hidden = NO;
    _photoImageView.image = nil;
    _index = NSUIntegerMax;
}

- (BOOL)displayingVideo {
    return [_photo respondsToSelector:@selector(isVideo)] && _photo.isVideo;
}

- (void)setImageHidden:(BOOL)hidden {
    _photoImageView.hidden = hidden;
}

#pragma mark - Image

- (void)setPhoto:(id <MWPhoto>)photo {
    // Cancel any loading on old photo
    if (_photo && photo == nil) {
        if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [_photo cancelAnyLoading];
        }
    }
    _photo = photo;
    UIImage *img = [_photoBrowser imageForPhoto:_photo];
    if (img) {
        [self displayImage];
    } else {
        // Will be loading so show loading
        [self showLoadingIndicator];
    }
}

// Get and display image
- (void)displayImage {
    if (_photo && _photoImageView.image == nil) {

        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);

        // Get image from browser as it handles ordering of fetching
        UIImage *img = [_photoBrowser imageForPhoto:_photo];
        if (img) {

            // Hide indicator
            [self hideLoadingIndicator];

            // Set image
            _photoImageView.image = img;
            _photoImageView.hidden = NO;

            // Setup photo frame
            CGRect photoImageViewFrame;
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = img.size;
            _photoImageView.frame = photoImageViewFrame;
            // 2017年11月12日将这一行放到scrollViewDidZoom方法中,(滚动结束后方法)
            // self.contentSize = photoImageViewFrame.size;

            // Set zoom to minimum zoom
            [self setMaxMinZoomScalesForCurrentBounds];
        } else {

            // Show image failure
            [self displayImageFailure];

        }
        [self setNeedsLayout];
    }
}

// Image failed so just show black!
- (void)displayImageFailure {
    [self hideLoadingIndicator];
    _photoImageView.image = nil;

    // Show if image is not empty
    if (![_photo respondsToSelector:@selector(emptyImage)] || !_photo.emptyImage) {
        if (!_loadingError) {
            _loadingError = [UIImageView new];
            _loadingError.image = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
            _loadingError.userInteractionEnabled = NO;
            _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            [_loadingError sizeToFit];
            [self addSubview:_loadingError];
        }
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                _loadingError.frame.size.width,
                _loadingError.frame.size.height);
    }
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

/**
 * 图片的布局
 * @return
 */
- (CGRect)imageFrame {
    if (_photoImageView.image != nil) {
        [self layoutSubviews];
        return _photoImageView.frame;
    }
    // 图片未加载返回视图frame
    return CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

#pragma mark - Loading Progress

- (void)setProgressFromNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification object];
        id <MWPhoto> photoWithProgress = [dict objectForKey:@"photo"];
        if (photoWithProgress == self.photo) {
            float progress = [[dict valueForKey:@"progress"] floatValue];
            _loadingIndicator.progress = MAX(MIN(1, progress), 0);
        }
    });
}

- (void)hideLoadingIndicator {
    _loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    // 修复<Error>: CGAffineTransformInvert: singular matrix。将0 改为0.0001f
    self.zoomScale = 0.0001f;//0;
    self.minimumZoomScale = 0.0001f;//0;
    self.maximumZoomScale = 0.0001f;//0;
    _loadingIndicator.progress = 0;
    _loadingIndicator.hidden = NO;
    [self hideImageFailure];
}

#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_photoImageView && _photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {

    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;

    // Bail if no image
    if (_photoImageView.image == nil) return;

    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);

    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;

    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible

    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }

    //如果图片不能够填充满一个屏幕,显示原来的大小
    // Image is smaller than screen so no zooming!
    //if (xScale >= 1 && yScale >= 1) {
    //    minScale = 1.0;
    //}

    // 修改 [如果图片不能够填充满一个屏幕,显示原来的大小] 为宽度或高度填充满屏幕
    maxScale = MAX(minScale, maxScale);
    minScale = MIN(minScale, maxScale);


    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;

    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];

    // If we're zooming to fill then centralise
    if (self.zoomScale != minScale) {

        // Centralise
        self.contentOffset = CGPointMake((imageSize.width * self.zoomScale - boundsSize.width) / 2.0,
                (imageSize.height * self.zoomScale - boundsSize.height) / 2.0);

    }

    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    //self.scrollEnabled = NO;

    // If it's a video then disable zooming
    if ([self displayingVideo]) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }

    // Layout
    [self setNeedsLayout];

}

#pragma mark - Layout

- (void)layoutSubviews {

    // Update tap view frame
    _tapView.frame = self.bounds;

    // Position indicators (centre does not seem to work!)
    if (!_loadingIndicator.hidden)
        _loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - _loadingIndicator.frame.size.width) / 2.),
                floorf((self.bounds.size.height - _loadingIndicator.frame.size.height) / 2),
                _loadingIndicator.frame.size.width,
                _loadingIndicator.frame.size.height);
    if (_loadingError)
        _loadingError.frame = CGRectMake(floorf((self.bounds.size.width - _loadingError.frame.size.width) / 2.),
                floorf((self.bounds.size.height - _loadingError.frame.size.height) / 2),
                _loadingError.frame.size.width,
                _loadingError.frame.size.height);

    // Super
    [super layoutSubviews];

    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;

    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }

    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }

    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter)) {
        _photoImageView.frame = frameToCenter;
        // 解决当图片分辨率不足以沾满屏幕,时候无法下滑关闭问题
        if (self.zoomScale == self.minimumZoomScale) {
            self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height + 1);
        }
    }

}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_photoBrowser cancelControlHiding];
    _parentView.scrollEnabled = NO;
    // 2017年11月12日 如果当前缩放是缩放到最小时允许,滑动使得图片浏览界面消失
    if (self.zoomScale == self.minimumZoomScale) {
        [_photoBrowser setControlsHidden:YES animated:YES permanent:YES];
        self.contentSize = CGSizeMake(self.frame.size.width + 1, self.frame.size.height + 1);
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_photoBrowser hideControlsAfterDelay];
    _parentView.scrollEnabled = YES;
    // 2017年11月12日 如果当前缩放是缩放到最小时允许,上下滑动使得图片浏览界面消失
    if (self.zoomScale == self.minimumZoomScale) {
        [_photoBrowser setControlsHidden:NO animated:YES permanent:NO];
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height + 1);
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    [_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
    // 2017年11月12日 如果当前缩放是缩放到最小时允许,上下滑动使得图片浏览界面消失
    if (self.zoomScale == self.minimumZoomScale) {
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height + 1);
    }
}

#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {

    // Dont double tap to zoom if showing a video
    if ([self displayingVideo]) {
        return;
    }

    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];

    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {

        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];

    } else {

        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];

    }

    // Delay controls
    [_photoBrowser hideControlsAfterDelay];

}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:imageView]];
}

- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1 / self.zoomScale;
    touchY *= 1 / self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}

- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1 / self.zoomScale;
    touchY *= 1 / self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

@end
