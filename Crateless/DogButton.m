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

- (void)setDogImage:(UIImage *)dogImage
{
    _dogImage = dogImage;
    
    [self setImage:dogImage forState:UIControlStateNormal];
    [self setImage:dogImage forState:UIControlStateHighlighted];
    [self setImage:dogImage forState:UIControlStateSelected];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
