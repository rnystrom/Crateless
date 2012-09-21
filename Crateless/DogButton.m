//
//  DogImageView.m
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import "DogButton.h"

@implementation DogButton

#pragma mark - Setters

- (void)setDog:(Dog *)dog
{
    _dog = dog;
    
    [self setBackgroundImage:dog.image forState:UIControlStateNormal];
    [self setBackgroundImage:dog.image forState:UIControlStateHighlighted];
    [self setBackgroundImage:dog.image forState:UIControlStateSelected];
    
    UIImage *coverImage = [UIImage imageNamed:@"dog-overlay"];
    [self setImage:coverImage forState:UIControlStateNormal];
    [self setImage:coverImage forState:UIControlStateHighlighted];
    [self setImage:coverImage forState:UIControlStateSelected];
    
    CGFloat width = 0;
    if (self.superview) {
        width = self.superview.bounds.size.width;
    }
    else {
        width = self.bounds.size.width;
    }
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20.0f)];
    self.nameLabel.font = [UIFont fontWithName:@"LucidaGrande-Bold" size:20.0f];
    self.nameLabel.text = dog.name;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.textColor = [UIColor whiteColor];
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.nameLabel.shadowColor = [UIColor blackColor];
    self.nameLabel.shadowOffset = CGSizeMake(0, -1);
    self.nameLabel.center = CGPointMake(self.bounds.size.width / 2.0f, -20.0f);
    self.nameLabel.hidden = YES;
    
    [self addSubview:self.nameLabel];
}

- (void)reset
{
    [self setBackgroundImage:nil forState:UIControlStateNormal];
    [self setBackgroundImage:nil forState:UIControlStateHighlighted];
    [self setBackgroundImage:nil forState:UIControlStateSelected];
    
    UIImage *coverImage = [UIImage imageNamed:@"camera"];
    [self setImage:coverImage forState:UIControlStateNormal];
    [self setImage:coverImage forState:UIControlStateHighlighted];
    [self setImage:coverImage forState:UIControlStateSelected];
    
    [self.nameLabel removeFromSuperview];
    self.nameLabel = nil;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (self.nameLabel) {
        self.nameLabel.center = CGPointMake(frame.size.width / 2.0f, -20.0f);
    }
}

@end
