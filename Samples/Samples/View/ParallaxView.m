//
//  ParallaxView.m
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "ParallaxView.h"
#import "ViewController.h"

@implementation ParallaxViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.size = CGSizeMake(self.width, self.height);
}

@end


#define AUTO_SCROLL_INTERVAL    5.0
#define CELL_IDENTIFIER_COMMON  @"CommonCell"

static void *ParallaxSuperObserverContext = &ParallaxSuperObserverContext;  // Scroll super view

@interface ParallaxView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) ParallaxViewCell *backgroundCell;
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
    
    if (self.pageCount > 1) {
        self.targetContentOffset = CGPointMake(self.width, self.contentOffset.y);
        [self setContentOffset:self.targetContentOffset animated:NO];
    }
}

- (void)updatePageControl
{
    NSUInteger itemCount = [self numberOfItemsInSection:0];
    if (itemCount > 1) {
        self.pageControl.hidden = NO;
        self.pageControl.numberOfPages = itemCount - 2;
    } else {
        self.pageControl.hidden = YES;
        self.scrollEnabled = NO;
    }
}

- (void)didMoveToSuperview
{
    if (self.superScrollView) {
        self.top = -self.height;
        self.superScrollView.contentInset = UIEdgeInsetsMake(self.height, 0, 0, 0);
    }
    
    [self addObservers];
}

#pragma mark - Collection view data source
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([self.customDataSource respondsToSelector:@selector(numberOfPages)]) {
        self.pageCount = [self.customDataSource numberOfPages];
    }
    return (self.pageCount > 1) ? self.pageCount + 2 : self.pageCount;  // For endless scrolling
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ParallaxViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER_COMMON forIndexPath:indexPath];

    if (indexPath.item == 0) {
        indexPath = [NSIndexPath indexPathForItem:self.pageCount - 1 inSection:indexPath.section];
    } else if (indexPath.item - 1 < self.pageCount) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
    } else {
        indexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
    }
    [self.customDataSource parallaxView:self configCell:cell forPageIndexPath:indexPath];
    
    // Set background view
    if (!self.backgroundView) {
        if (indexPath.item == 0) {
            cell.hidden = YES;
        }
        
        self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        self.backgroundCell = [[ParallaxViewCell alloc] initWithFrame:self.backgroundView.bounds];
        [self.customDataSource parallaxView:self configCell:self.backgroundCell forPageIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        [self.backgroundView addSubview:self.backgroundCell];
    }
    
    return cell;
}

#pragma mark - Scroll view delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat offsetX = ABS(contentOffset.x - self.width);
    
    if (contentOffset.x >= self.width) {
        self.backgroundCell.left = 0;
        self.backgroundCell.width = self.width - offsetX;
    } else {
        self.backgroundCell.left = offsetX;
        self.backgroundCell.width = self.width - offsetX;
    }
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
    [self updateUI];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.targetContentOffset = self.contentOffset;
    [self updateUI];
}

- (void)updateUI
{
    NSIndexPath *indexPath = nil;
    if (self.contentOffset.x == 0) {
        self.pageControl.currentPage = self.pageCount - 1;
        indexPath = [NSIndexPath indexPathForItem:self.pageCount inSection:0];
    } else if (self.contentOffset.x == self.contentSize.width - self.width) {
        self.pageControl.currentPage = 0;
        indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
    } else {
        self.pageControl.currentPage = (self.contentOffset.x / self.width) - 1;
        indexPath = [NSIndexPath indexPathForItem:self.pageControl.currentPage + 1 inSection:0];
    }
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
    // Update background view
//    self.backgroundView = [[ParallaxViewCell alloc] initWithFrame:self.frame];
//    [self.customDataSource parallaxView:self configCell:(id)self.backgroundView forPageIndexPath:[NSIndexPath indexPathForItem:indexPath.item-1 inSection:0]];
//    ParallaxViewCell *visibleCell = (id)[self cellForItemAtIndexPath:indexPath];
//    visibleCell.hidden = YES;
}

#pragma mark - Observe superView's content offset
- (void)addObservers
{
    [self.superScrollView addObserver:self
                           forKeyPath:self.contentOffsetKeyPath
                              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                              context:ParallaxSuperObserverContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAutoScrollScheduler) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAutoScrollScheduler) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (UIScrollView *)superScrollView
{
    return ([self.superview isKindOfClass:[UIScrollView class]]) ? (id)self.superview : nil;
}

- (void)dealloc
{
    [self.superScrollView removeObserver:self forKeyPath:self.contentOffsetKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)contentOffsetKeyPath
{
    return NSStringFromSelector(@selector(contentOffset));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == ParallaxSuperObserverContext) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        CGFloat originalHeight = self.originalSize.height;
        CGFloat offsetY = contentOffset.y + originalHeight;
        
//      Resize frame
        self.top = contentOffset.y;
        self.height = originalHeight - offsetY;
        
//      Update navigation
        if (!self.navigationBar) return;
        CGPoint preContentOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
        CGFloat diffY = contentOffset.y - preContentOffset.y;
        CGFloat navHeight = self.navigationBar.height;
        
        if (offsetY > 0 && offsetY < originalHeight) {
            self.alpha = 1 - (ABS(offsetY) / originalHeight);
            if (originalHeight - offsetY > navHeight) {
                self.navBackgroundView.alpha = 0;
            } else {
                self.navBackgroundView.alpha = self.alpha + 1;
            }
        } else {
            if (ABS(diffY) > 5) {
                NSInteger hidden = (diffY > 0) ? YES : NO;
                if ((hidden && !self.navigationBar.hidden) || (!hidden && self.navigationBar.hidden)) {
                    [UIView animateWithDuration:0.25 animations:^{
                        self.navigationBar.transform = hidden ? CGAffineTransformMakeTranslation(0, -self.navigationBar.height) : CGAffineTransformIdentity;
                    } completion:^(BOOL finished) {
                        self.navigationBar.hidden = hidden;
                    }];
                }
            }
        }
    }
}

- (UIView *)navigationBar
{
    return [(ViewController *)self.superViewController navgationView];
}

- (UIView *)navBackgroundView
{
    // FIXME: Get navigation background view
    return [(ViewController *)self.superViewController navgationView];
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
    if (self.isTracking || self.superScrollView.isTracking || self.superScrollView.isDecelerating) {
        return;
    }
    
    NSUInteger item = self.pageControl.currentPage + 2;
    item = (item < [self numberOfItemsInSection:0]) ? item : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}

@end
