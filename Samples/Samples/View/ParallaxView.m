//
//  ParallaxView.m
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "ParallaxView.h"

#define AUTO_SCROLL_INTERVAL    5.0
#define CELL_IDENTIFIER_COMMON  @"CommonCell"

static void *ParallaxSuperObserverContext = &ParallaxSuperObserverContext;  // Scroll super view

@interface ParallaxView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGPoint targetContentOffset;

@end

@implementation ParallaxView

+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount
{
    return [[self alloc] initWithFrame:frame pageCount:pageCount];
}

- (instancetype)initWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = frame.size;
    flowLayout.minimumLineSpacing = 0;
    
    if (self = [super initWithFrame:frame collectionViewLayout:flowLayout]) {
        self.originalSize = self.size;
        self.pageCount = pageCount;
        
        self.backgroundColor = [UIColor clearColor];
        self.dataSource = self;
        self.delegate = self;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        [self registerClass:[ParallaxViewCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER_COMMON];
        
        [self addSubviews];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [(id)self.collectionViewLayout setItemSize:frame.size];
    [super setFrame:frame];
    self.contentOffset = self.targetContentOffset;
}

- (void)addSubviews
{
    _pageControl = [[UIPageControl alloc] init];
    self.pageControl.enabled = NO;
    self.pageControl.size = CGSizeMake(self.width, 10);
    [self addSubview:self.pageControl];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.pageControl.top = self.height - 20;
    self.pageControl.centerX = self.centerX + self.contentOffset.x;
}

- (void)reloadData
{
    [super reloadData];
    [self updatePageControl];
    [self startAutoScrollScheduler];
}

- (void)updatePageControl
{
    NSUInteger itemCount = [self numberOfItemsInSection:0];
    if (itemCount > 1) {
        self.pageControl.hidden = NO;
        self.pageControl.numberOfPages = itemCount;
    } else {
        self.pageControl.hidden = YES;
        self.scrollEnabled = NO;
    }
}

- (void)didMoveToSuperview
{
    if ([self.superview respondsToSelector:@selector(contentInset)]) {
        self.top = -self.height;
        [(id)self.superview setContentInset:UIEdgeInsetsMake(self.height, 0, 0, 0)];
    }
    
    [self addObservers];
}

#pragma mark - Collection view data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self.customDataSource respondsToSelector:@selector(numberOfPages)]) {
        self.pageCount = [self.customDataSource numberOfPages];
    }
    return self.pageCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ParallaxViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER_COMMON forIndexPath:indexPath];
    [self.customDataSource parallaxView:self configCell:cell forPageIndexPath:indexPath];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    CGPoint contentOffset = scrollView.contentOffset;
//    UICollectionViewCell *currCell = [self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//    UICollectionViewCell *nextCell = [self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
//    currCell.width = self.width - contentOffset.x;
//    nextCell.left = self.width - contentOffset.x;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    self.targetContentOffset = *targetContentOffset;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self stopAutoScrollScheduler];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self startAutoScrollScheduler];
    self.pageControl.currentPage = self.contentOffset.x / self.width;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.targetContentOffset = self.contentOffset;
    self.pageControl.currentPage = self.contentOffset.x / self.width;
}

#pragma mark - Observe superView's content offset
- (void)addObservers
{
    [self.superview addObserver:self forKeyPath:self.contentOffsetKeyPath options:NSKeyValueObservingOptionNew context:ParallaxSuperObserverContext];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:self.contentOffsetKeyPath];
    [self.superview removeObserver:self forKeyPath:self.contentOffsetKeyPath];
}

- (NSString *)contentOffsetKeyPath
{
    return NSStringFromSelector(@selector(contentOffset));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == ParallaxSuperObserverContext) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        CGFloat offsetY = contentOffset.y + self.originalSize.height;
        self.top = contentOffset.y;
        self.height = self.originalSize.height - offsetY;
    }
}

- (void)updateNavigationBar
{
    
}

#pragma mark - Auto scroll
- (void)startAutoScrollScheduler
{
    if (!self.isAutoScrolling) return;
    
    [self stopAutoScrollScheduler];
    self.timer = [NSTimer timerWithTimeInterval:AUTO_SCROLL_INTERVAL target:self selector:@selector(scrollPage) userInfo:nil repeats:YES];
    [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:AUTO_SCROLL_INTERVAL]];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopAutoScrollScheduler
{
    [self.timer invalidate];
}

- (void)scrollPage
{
    if (self.isTracking || ([self.superview respondsToSelector:@selector(isTracking)] && [(id)self.superview isTracking])) {
        return;
    }
    
    NSUInteger item = self.pageControl.currentPage + 1;
    item = (item < self.pageCount) ? item : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

@end
