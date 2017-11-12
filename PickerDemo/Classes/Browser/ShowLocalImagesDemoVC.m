//
//  ShowLocalImagesDemoVC.m
//  XLImageViewerDemo
//
//  Created by Apple on 2017/2/23.
//  Copyright © 2017年 Apple. All rights reserved.
// [[NSBundle mainBundle] pathForResource:@"RecordTest" ofType:@"m4a"]

#import "ShowLocalImagesDemoVC.h"
#import "XLImageViewer.h"
#import "ImageCell.h"

@interface ShowLocalImagesDemoVC () <UICollectionViewDelegate, UICollectionViewDataSource> {
    UICollectionView *_collectionView;
}
@end

@implementation ShowLocalImagesDemoVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self buildUI];
}

- (NSArray *)imagePathes {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *data = @[[[NSBundle mainBundle] pathForResource:@"1" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"2" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"3" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"4" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"5" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"6" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"7" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"8" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"9" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"10" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"11" ofType:@"png"],
            [[NSBundle mainBundle] pathForResource:@"12" ofType:@"png"]];

    return array;
}

- (void)buildUI {
    self.view.backgroundColor = [UIColor whiteColor];
    self.displaySelectionButtons = YES;

    NSInteger ColumnNumber = 3;
    CGFloat imageMargin = 10.0f;
    CGFloat itemWidth = (self.view.bounds.size.width - (ColumnNumber + 1) * imageMargin) / ColumnNumber;

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 0);
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.alwaysBounceVertical = YES; //垂直方向遇到边框是否总是反弹
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.backgroundColor = [UIColor clearColor];
    [_collectionView registerClass:[ImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Option" style:UIBarButtonItemStylePlain target:self action:@selector(optionButtonPressed:)];

    [self.view addSubview:_collectionView];
}

#pragma mark -
#pragma mark CollectionViewDelegate&DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self imagePathes].count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"ImageCell";
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.layer.borderWidth = 1.0f;
    cell.gridController = self;
    cell.index = (NSUInteger) indexPath.row;
    cell.selectionMode = self.displaySelectionButtons;
    cell.photo = [self imagePathes][indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    //利用XLImageViewer显示本地图片
    [[XLImageViewer shareInstanse] showLocalImages:[self imagePathes] index:indexPath.row fromImageContainer:[collectionView cellForItemAtIndexPath:indexPath]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)optionButtonPressed:(id)sender {
}

@end
