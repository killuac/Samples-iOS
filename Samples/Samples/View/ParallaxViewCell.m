//
//  ParallaxViewCell.m
//  Samples
//
//  Created by Killua Liu on 4/15/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "ParallaxViewCell.h"

@implementation ParallaxViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
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
