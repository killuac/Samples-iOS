//
//  ParallaxView.m
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "KLParallaxView.h"

@implementation KLParallaxViewCell

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


#define AUTO_SCROLL_INTERVAL        5.0
#define CELL_IDENTIFIER_COMMON      @"CommonCell"

static void *ParallaxSuperObserverContext = &ParallaxSuperObserverContext;  // Scroll super view

@interface KLParallaxView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) NSUInteger pageCount;
@property (nonatomic, assign) BOOL isAnimated;
@property (nonatomic, strong) KLParallaxViewCell *backgroundCell;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) CGPoint targetContentOffset;

@property (nonatomic, assign) BOOL isLeftScroll;    // Auto scroll is to left
@property (nonatomic, assign) BOOL needHideCell;    // For parallax effort
@property (nonatomic, strong) KLParallaxViewCell *hiddenCell;

@end

@implementation KLParallaxView

+ (instancetype)parallaxViewWithFrame:(CGRect)frame
{
    return [[self alloc] initWithFrame:frame pageCount:0 animated:NO];
}

+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount
{
    return [[self alloc] initWithFrame:frame pageCount:pageCount animated:NO];
}

+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount animated:(BOOL)isAnimated
{
    return [[self alloc] initWithFrame:frame pageCount:pageCount animated:isAnimated];
}

- (instancetype)initWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount animated:(BOOL)isAnimated
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = frame.size;
    flowLayout.minimumLineSpacing = 0;
    
    if (self = [super initWithFrame:frame collectionViewLayout:flowLayout]) {
        self.originalSize = self.size;
        self.pageCount = pageCount;
        self.isAnimated = isAnimated;
        
        self.dataSource = self;
        self.delegate = self;
        self.pagingEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.backgroundView = [[UIView alloc] initWithFrame:frame];
        [self registerClass:[KLParallaxViewCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER_COMMON];
        
        [self addSubviews];
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [(id)self.collectionViewLayout setItemSize:frame.size];
    [super setFrame:frame];
    
    self.backgroundCell.frame = self.backgroundView.bounds;
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

- (UIScrollView *)superScrollView
{
    return [self.superview isKindOfClass:[UIScrollView class]] ? (id)self.superview : nil;
}

- (void)didMoveToSuperview
{
    if (self.superScrollView) {
        self.superScrollView.contentInset = UIEdgeInsetsMake(self.height, 0, 0, 0);
        
        if (self.isAnimated) {
            self.superScrollView.contentOffset = CGPointZero;
            [self performSelector:@selector(animateShow) withObject:nil afterDelay:0.4];
        }
    }
    
    [self addObservers];
}

- (void)animateShow
{
    [self.superScrollView setContentOffset:CGPointMake(0, -self.originalSize.height) animated:YES];
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
//  Cell indexPath
    KLParallaxViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER_COMMON forIndexPath:indexPath];
    cell.hidden = NO;
    
//  Data source indexPath
    NSIndexPath *dsIndexPath = nil;
    if (indexPath.item == 0) {
        dsIndexPath = [NSIndexPath indexPathForItem:self.pageCount - 1 inSection:indexPath.section];
    } else if (indexPath.item - 1 < self.pageCount) {
        dsIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inSection:indexPath.section];
    } else {
        dsIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
    }
    [self.customDataSource parallaxView:self configCell:cell forPageIndexPath:dsIndexPath];
    
//  Set background view for parallax effect
    if (!self.backgroundCell && dsIndexPath.item == 0 && self.pageCount > 1) {
        self.backgroundCell = [[KLParallaxViewCell alloc] initWithFrame:self.backgroundView.bounds];
        self.needHideCell = YES;
    }
    
    if (self.needHideCell) {
        self.hiddenCell = cell;
        self.needHideCell = NO;
    }
    
    return cell;
}

- (void)setBackgroundCell:(KLParallaxViewCell *)backgroundCell
{
    [_backgroundCell removeFromSuperview];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.pageControl.currentPage inSection:0];
    [self.customDataSource parallaxView:self configCell:backgroundCell forPageIndexPath:indexPath];
    [self.backgroundView addSubview:backgroundCell];
    
    _backgroundCell = backgroundCell;
}

#pragma mark - Scroll view delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return !(self.isDragging || self.isDecelerating || self.superScrollView.isDragging || self.superScrollView.isDecelerating);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.superScrollView.isDecelerating) return;
    
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat xOffset = ABS(contentOffset.x - self.width * (self.pageControl.currentPage + 1));
    
    if (self.isLeftScroll || [self.panGestureRecognizer translationInView:scrollView].x <= 0) {
        self.backgroundCell.left = -xOffset * 0.5;  // Left scroll
    } else {
        self.backgroundCell.left = xOffset * 0.5;   // Right scroll
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    self.targetContentOffset = *targetContentOffset;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self stopAutoScrollScheduler];
    self.isLeftScroll = NO;
    self.hiddenCell.hidden = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self startAutoScrollScheduler];
    [self updateUI];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateUI];
}

- (void)updateUI
{
//  Set content offset for endless scroll
    NSUInteger itemIndex = 0;
    if (self.contentOffset.x == 0) {
        self.pageControl.currentPage = self.pageCount - 1;
        itemIndex = self.pageCount;
    } else if (self.contentOffset.x == self.contentSize.width - self.width) {
        self.pageControl.currentPage = 0;
        itemIndex = 1;
    } else {
        self.pageControl.currentPage = (self.contentOffset.x / self.width) - 1;
        itemIndex = self.pageControl.currentPage + 1;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
//  Set background cell and hide cell
//  Maybe visible is nil since reset content offset for endless scroll, so need hide cell in method "collectionView:cellForItemAtIndexPath:"
    self.backgroundCell = [[KLParallaxViewCell alloc] initWithFrame:self.backgroundView.bounds];
    KLParallaxViewCell *visibleCell = (id)[self cellForItemAtIndexPath:indexPath];
    if (visibleCell) {
        self.hiddenCell = visibleCell;
    } else {
        self.needHideCell = YES;
    }
    self.hiddenCell.hidden = NO;
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
        CGFloat yOffset = contentOffset.y + originalHeight;
        
//      Resize frame
        self.top = contentOffset.y;
        self.height = originalHeight - yOffset;
        
//      Update navigation
        if (!self.navigationBar) return;
        CGPoint preContentOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
        CGFloat yDiff = contentOffset.y - preContentOffset.y;
        CGFloat navHeight = self.navigationBar.height;
        
        if (yOffset > 0 && yOffset < originalHeight) {
            self.alpha = 1 - (ABS(yOffset) / originalHeight);
            if (originalHeight - yOffset > navHeight) {
                self.navigationBar.backgroundColor = [self.navigationBar.backgroundColor colorWithAlphaComponent:0];
            } else {
                self.navigationBar.backgroundColor = [self.navigationBar.backgroundColor colorWithAlphaComponent:(self.alpha + 1)];
            }
        } else {
            if (ABS(yDiff) > 5) {
                NSInteger hidden = (yDiff > 0) ? YES : NO;
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
    if ([self.viewController respondsToSelector:@selector(navigationBar)]) {
        return [(id)self.viewController navigationBar];
    } else {
        return self.viewController.navigationController.navigationBar;
    }
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
    if (self.isTracking || self.isDecelerating || self.superScrollView.isTracking || self.superScrollView.isDecelerating) {
        return;
    }
    
    self.isLeftScroll = YES;
    self.hiddenCell.hidden = YES;
    
    NSUInteger itemIndex = self.pageControl.currentPage + 2;
    itemIndex = (itemIndex < [self numberOfItemsInSection:0]) ? itemIndex : 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}

@end
