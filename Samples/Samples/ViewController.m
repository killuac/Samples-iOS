//
//  ViewController.m
//  Samples
//
//  Created by Bing Liu on 3/14/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "ViewController.h"
#import "ParallaxView.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, ParallaxViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

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
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TableCell"];
    
    ParallaxView *parallaxView = [ParallaxView parallaxViewWithFrame:self.view.frame pageCount:3];
    parallaxView.customDataSource = self;
    parallaxView.isAutoScrolling = YES;
    [self.tableView addSubview:parallaxView];
    
    _navgationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 44)];
    _navgationView.alpha = 0;
    _navgationView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.navgationView];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
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
}

@end
