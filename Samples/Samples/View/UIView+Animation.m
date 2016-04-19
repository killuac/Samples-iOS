//
//  UIView+Animation.m
//  Bookworm
//
//  Created by Killua Liu on 12/16/15.
//  Copyright (c) 2015 Syzygy. All rights reserved.
//

#import "UIView+Animation.h"

@implementation UIButton (Animation)

- (void)startScaleAnimation
{
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5f initialSpringVelocity:10 options:0 animations:^{
        self.transform = CGAffineTransformMakeScale(1.1, 1.1);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
    }];
}

@end
