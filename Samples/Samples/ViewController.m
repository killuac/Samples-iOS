//
//  ViewController.m
//  Samples
//
//  Created by Bing Liu on 3/14/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "ViewController.h"
#import "ParallaxView.h"
#import "UIView+Animation.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, ParallaxViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *shoppingCart;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addSubviews];
}

- (void)addSubviews
{
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.allowsSelection = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TableCell"];
    
    ParallaxView *parallaxView = [ParallaxView parallaxViewWithFrame:self.view.bounds pageCount:3 animated:YES];
    parallaxView.customDataSource = self;
//    parallaxView.isAutoScrolling = YES;
    [self.tableView addSubview:parallaxView];
    
    _navgationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
    _navgationView.alpha = 0;
    _navgationView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.navgationView];
    
    self.shoppingCart = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shoppingCart setTitle:@"购物车" forState:UIControlStateNormal];
    self.shoppingCart.backgroundColor = [UIColor orangeColor];
    self.shoppingCart.frame = CGRectMake(0, 6, 50, 32);
    self.shoppingCart.right = self.view.width - 15;
    self.shoppingCart.layer.cornerRadius = 5;
    [self.tableView addSubview:self.shoppingCart];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"动画按钮" forState:UIControlStateNormal];
    button.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.9];
    button.frame = CGRectMake(0, 6, 100, 32);
    button.right = self.shoppingCart.left - 15;
    button.layer.cornerRadius = 5;
    [button addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableView addSubview:button];
}

- (void)pressed:(UIButton *)button
{
    [button startScaleAnimation];
}

#pragma mark - 购物车动画
- (void)startAnimationFromImageView:(UIImageView *)imageView toView:(UIView *)toView
{
    ParallaxView *parallaxView = [imageView superCollectionView];
    
    UIImageView *smallImageView = [[UIImageView alloc] initWithImage:imageView.image];
    smallImageView.contentMode = UIViewContentModeScaleAspectFill;
    smallImageView.clipsToBounds = YES;
    smallImageView.alpha = MAX(0.5, parallaxView.alpha - 0.2);
    smallImageView.size = CGSizeMake(30, 30);
    smallImageView.center = parallaxView.center;
    [toView.superview addSubview:smallImageView];
    
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat tx = toView.centerX - smallImageView.centerX;
        CGFloat ty = toView.centerY - smallImageView.centerY;
        smallImageView.transform = CGAffineTransformMakeTranslation(tx, ty);
    } completion:^(BOOL finished) {
        [smallImageView removeFromSuperview];
        [toView startScaleAnimation];
    }];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableCell" forIndexPath:indexPath];
    cell.textLabel.text = @"滚动测试";
    return cell;
}

#pragma mark - Collection view data source
- (void)parallaxView:(ParallaxView *)parallaxView configCell:(ParallaxViewCell *)cell forPageIndexPath:(NSIndexPath *)indexPath
{
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"guide%tu.jpg", indexPath.item]];
    [cell.imageView addTapGesture];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    [cell addGestureRecognizer:tap];
}

- (void)singleTap:(UITapGestureRecognizer *)recognizer
{
    UIImageView *imageView = (id)[recognizer.view.subviews.firstObject subviews].firstObject;
    [self startAnimationFromImageView:imageView toView:self.shoppingCart];
}

@end
