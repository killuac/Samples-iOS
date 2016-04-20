//
//  KLParallaxView.h
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KLParallaxViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;

@end


@class KLParallaxView;

@protocol KLParallaxViewDataSource <NSObject>

- (void)parallaxView:(KLParallaxView *)parallaxView configCell:(KLParallaxViewCell *)cell forPageIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSUInteger)numberOfPages;

@end


@interface KLParallaxView : UICollectionView

+ (instancetype)parallaxViewWithFrame:(CGRect)frame;
+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount;
+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount animated:(BOOL)isAnimated;

@property (nonatomic, strong) id <KLParallaxViewDataSource> customDataSource;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) BOOL isAutoScrolling;     // Is auto scroll page, default is NO.

@end
