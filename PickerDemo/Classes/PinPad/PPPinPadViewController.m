//
//  VTPinPadViewController.m
//  PinPad
//
//  Created by Aleks Kosylo on 1/15/14.
//  Copyright (c) 2014 Aleks Kosylo. All rights reserved.
//

#import "PPPinPadViewController.h"
#import "PPPinCircleView.h"
#import "AppDelegate.h"


#define PP_SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)


typedef NS_ENUM(NSInteger, settingNewPinState) {
    settingMewPinStateFirst = 0,
    settingMewPinStateConfirm = 1
};

@interface PPPinPadViewController () {
    NSInteger _shakes;
    NSInteger _direction;
}
@property(nonatomic) settingNewPinState newPinState;
@property(nonatomic, strong) NSString *firstPassCode;
@property(weak, nonatomic) IBOutlet    UILabel *laInstructionsLabel;
@end

static CGFloat kVTPinPadViewControllerCircleRadius = 6.0f;

@implementation PPPinPadViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self addCircles];//在viewWillLayoutSubviews才能得到正确的宽高
    pinLabel.text = self.pinTitle ?: @"Enter PIN";
    pinErrorLabel.text = self.errorTitle ?: @"PIN number is not correct";
    cancelButton.hidden = self.cancelButtonHidden;
    if (self.backgroundImage) {
        backgroundImageView.hidden = NO;
        backgroundImageView.image = self.backgroundImage;
    }

    if (self.backgroundColor && !self.backgroundImage) {
        backgroundImageView.hidden = YES;
        self.view.backgroundColor = self.backgroundColor;
    }
}

- (void)viewWillLayoutSubviews {
    [self addCircles];//在viewWillLayoutSubviews才能得到正确的宽高
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 恢复屏幕亮度
    if ([UIScreen mainScreen].brightness < 0.01) {
        if ([AppDelegate getScreenBrightness] < 0.01) {
            [[UIScreen mainScreen] setBrightness:0.1];
        } else {
            [[UIScreen mainScreen] setBrightness:[AppDelegate getScreenBrightness]];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden {
    _cancelButtonHidden = cancelButtonHidden;
    cancelButton.hidden = cancelButtonHidden;
}

- (void)setErrorTitle:(NSString *)errorTitle {
    _errorTitle = errorTitle;
    pinErrorLabel.text = errorTitle;
}

- (void)setPinTitle:(NSString *)pinTitle {
    _pinTitle = pinTitle;
    pinLabel.text = pinTitle;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    backgroundImageView.image = backgroundImage;
    backgroundImageView.hidden = NO;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.view.backgroundColor = backgroundColor;
    backgroundImageView.hidden = YES;
}


- (void)dismissPinPad {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pinPadWillHide)]) {
        [self.delegate pinPadWillHide];
    }

    // 这个操作非常耗时,不知道怎么解决
    //NSDate* tmpStartData = [NSDate date];
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(pinPadDidHide)]) {
            [self.delegate pinPadDidHide];
        }
        //NBULogInfo(@"执行时间 = %f", [[NSDate date] timeIntervalSinceDate:tmpStartData]);
    }];
}


#pragma mark Status Bar

- (void)changeStatusBarHidden:(BOOL)hidden {
    _errorView.hidden = hidden;
    if (PP_SYSTEM_VERSION_GREATER_THAN(@"6.9")) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)prefersStatusBarHidden {
    return !_errorView.hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)setIsSettingPinCode:(BOOL)isSettingPinCode {
    _isSettingPinCode = isSettingPinCode;
    if (isSettingPinCode) {
        self.newPinState = settingMewPinStateFirst;
    }
}

#pragma mark Actions

- (IBAction)cancelClick:(id)sender {
    [self dismissPinPad];
}

- (IBAction)resetClick:(id)sender {
    [self addCircles];
    self.newPinState = settingMewPinStateFirst;
    self.laInstructionsLabel.text = NSLocalizedString(@"Enter PassCode", @"");
    _inputPin = [NSMutableString string];
}


- (IBAction)numberButtonClick:(id)sender {
    if (!_inputPin) {
        _inputPin = [NSMutableString new];
    }
    if (!_errorView.hidden) {
        [self changeStatusBarHidden:YES];
    }
    [_inputPin appendString:[((UIButton *) sender) titleForState:UIControlStateNormal]];
    [self fillingCircle:_inputPin.length - 1];

    if (self.isSettingPinCode) {
        if ([self pinLength] == _inputPin.length) {
            if (self.newPinState == settingMewPinStateFirst) {
                self.firstPassCode = _inputPin;
                // reset and prepare for confirmation stage
                [self resetClick:Nil];
                self.newPinState = settingMewPinStateConfirm;
                // update instruction label
                self.laInstructionsLabel.text = NSLocalizedString(@"Confirm PassCode", @"");
            } else {
                // we are at confirmation stage check this pin with original one
                if ([self.firstPassCode isEqualToString:_inputPin]) {
                    // every thing is ok
                    if ([self.delegate respondsToSelector:@selector(userPassCode:)]) {
                        [self.delegate userPassCode:self.firstPassCode];
                    }
                    [self dismissPinPad];
                } else {
                    // reset to first stage
                    self.laInstructionsLabel.text = NSLocalizedString(@"Enter PassCode", @"");
                    _direction = 1;
                    _shakes = 0;
                    [self shakeCircles:_pinCirclesView];
                    [self changeStatusBarHidden:NO];
                    [self resetClick:Nil];
                }
            }
        }
    } else {
        if ([self pinLength] == _inputPin.length && [self checkPin:_inputPin]) {
            double delayInSeconds = 0.3;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                NBULogInfo(@"Correct pin");
                [self resetClick:nil];
                if (self.delegate && [self.delegate respondsToSelector:@selector(pinPadSuccessPin)]) {
                    [self.delegate pinPadSuccessPin];
                }
                [self dismissPinPad];
            });

        } else if ([self pinLength] == _inputPin.length) {
            _direction = 1;
            _shakes = 0;
            [self shakeCircles:_pinCirclesView];
            //[self changeStatusBarHidden:NO];
            NBULogInfo(@"Not correct pin");
        }
    }
}

#pragma mark Delegate & methods

- (void)setDelegate:(id <PinPadPasswordProtocol>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        [self addCircles];
    }
}

- (BOOL)checkPin:(NSString *)pinString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(checkPin:)]) {
        return [self.delegate checkPin:pinString];
    }
    return NO;
}

- (NSInteger)pinLength {
    if ([self.delegate respondsToSelector:@selector(pinLength)]) {
        return [self.delegate pinLength];
    }
    return 4;
}

#pragma mark Circles

- (void)addCircles {
    if ([self isViewLoaded] && self.delegate) {
        //返回的是带有状态栏的Rect
        CGRect bound = [[UIScreen mainScreen] bounds];

        [[_pinCirclesView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_circleViewList removeAllObjects];
        _circleViewList = [NSMutableArray array];

        CGFloat neededWidth = [self pinLength] * kVTPinPadViewControllerCircleRadius;
        CGFloat shiftBetweenCircle = (/*_pinCirclesView.frame.size.width*/bound.size.width - neededWidth) / ([self pinLength] + 2);
        CGFloat indent = (CGFloat) (1.5 * shiftBetweenCircle);//第一项与左边间距
        if (shiftBetweenCircle > kVTPinPadViewControllerCircleRadius * 5.0f) {
            shiftBetweenCircle = kVTPinPadViewControllerCircleRadius * 5.0f;
            indent = (/*_pinCirclesView.frame.size.width*/bound.size.width - neededWidth - shiftBetweenCircle * ([self pinLength] > 1 ? [self pinLength] - 1 : 0)) / 2;
        }
        for (int i = 0; i < [self pinLength]; i++) {
            PPPinCircleView *circleView = [PPPinCircleView circleView:kVTPinPadViewControllerCircleRadius];
            CGRect circleFrame = circleView.frame;
            circleFrame.origin.x = indent + i * kVTPinPadViewControllerCircleRadius + i * shiftBetweenCircle;
            circleFrame.origin.y = (CGRectGetHeight(_pinCirclesView.frame) - kVTPinPadViewControllerCircleRadius) / 2.0f;
            circleView.frame = circleFrame;
            [_pinCirclesView addSubview:circleView];
            [_circleViewList addObject:circleView];
        }
    }
}

- (void)fillingCircle:(NSUInteger)symbolIndex {
    if (symbolIndex >= _circleViewList.count)
        return;
    PPPinCircleView *circleView = _circleViewList[symbolIndex];
    circleView.backgroundColor = [UIColor whiteColor];
}

#pragma mark 摇一摇

- (void)shakeCircles:(UIView *)theOneYouWannaShake {
    [UIView animateWithDuration:0.05 animations:^{
                theOneYouWannaShake.transform = CGAffineTransformMakeTranslation(10 * _direction, 0);
            }
                     completion:^(BOOL finished) {
                         if (_shakes >= 10) {
                             theOneYouWannaShake.transform = CGAffineTransformIdentity;
                             [self resetClick:nil];
                             return;
                         }
                         _shakes++;
                         _direction = _direction * -1;
                         [self shakeCircles:theOneYouWannaShake];
                     }];
}
@end
