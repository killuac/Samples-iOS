//
//  ParallaxView.h
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ParallaxViewCell : UICollectionViewCell

@property (nonatomic, strong, readonly) UIImageView *imageView;

@end


@class ParallaxView;

@protocol ParallaxViewDataSource <NSObject>

- (void)parallaxView:(ParallaxView *)parallaxView configCell:(ParallaxViewCell *)cell forPageIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSUInteger)numberOfPages;

@end


@interface ParallaxView : UICollectionView

+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount;
+ (instancetype)parallaxViewWithFrame:(CGRect)frame pageCount:(NSUInteger)pageCount animated:(BOOL)isAnimated;

@property (nonatomic, strong) id <ParallaxViewDataSource> customDataSource;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, assign) BOOL isAutoScrolling;     // Is auto scroll page, default is NO.

@end
