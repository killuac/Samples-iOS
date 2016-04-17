//
//  DotAnimationView.m
//  Samples
//
//  Created by Killua Liu on 3/14/16.
//  Copyright © 2016 Syzygy. All rights reserved.
//

#import "DotAnimationView.h"

@interface DotAnimationView ()

@property (nonatomic, strong) UIView *dot1;
@property (nonatomic, strong) UIView *dot2;
@property (nonatomic, strong) UIView *dot3;

@end

@implementation DotAnimationView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addSubviews];
        [self startAnimation];
    }
    return self;
}

- (void)startAnimation
{
    [self animate1];
    [self animate2];
    [self animate3];
}

- (void)addSubviews
{
    self.dot1 = [[UIView alloc] init];
    self.dot1.left = 150;
    self.dot1.centerY = self.centerY;
    self.dot1.size = CGSizeMake(10, 10);
    self.dot1.backgroundColor = [UIColor grayColor];
    self.dot1.clipsToBounds = YES;
    self.dot1.layer.cornerRadius = 5;
    [self addSubview:self.dot1];
    
    self.dot2 = [[UIView alloc] init];
    self.dot2.frame = self.dot1.frame;
    self.dot2.left = self.dot1.left + 20;
    self.dot2.backgroundColor = self.dot1.backgroundColor;
    self.dot2.clipsToBounds = YES;
    self.dot2.layer.cornerRadius = 5;
    [self addSubview:self.dot2];
    
    self.dot3 = [[UIView alloc] init];
    self.dot3.frame = self.dot2.frame;
    self.dot3.left = self.dot2.left + 20;
    self.dot3.backgroundColor = self.dot2.backgroundColor;
    self.dot3.clipsToBounds = YES;
    self.dot3.layer.cornerRadius = 5;
    [self addSubview:self.dot3];
}

- (void)animate1
{
    [UIView animateWithDuration:0.25 animations:^{
        self.dot1.transform = CGAffineTransformMakeTranslation(0, -10);
    } completion:^(BOOL finished) {
        [self reverse1];
    }];
}

- (void)reverse1
{
    [UIView animateWithDuration:0.25 animations:^{
        self.dot1.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(animate1) withObject:nil afterDelay:0.75];
    }];
}

- (void)animate2
{
    [UIView animateWithDuration:0.25
                          delay:0.25
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.dot2.transform = CGAffineTransformMakeTranslation(0, -10);
                     } completion:^(BOOL finished) {
                         [self reverse2];
                     }];
}

- (void)reverse2
{
    [UIView animateWithDuration:0.25 animations:^{
        self.dot2.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(animate2) withObject:nil afterDelay:0.5];
    }];
}

- (void)animate3
{
    [UIView animateWithDuration:0.25
                          delay:0.5
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.dot3.transform = CGAffineTransformMakeTranslation(0, -10);
                     } completion:^(BOOL finished) {
                         [self reverse3];
                     }];
}

- (void)reverse3
{
    [UIView animateWithDuration:0.25 animations:^{
        self.dot3.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(animate3) withObject:nil afterDelay:0.25];
    }];
}

@end
