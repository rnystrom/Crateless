//
//  ImagePickerCircleOverlay.m
//  Crateless
//
//  Created by Ryan Nystrom on 8/7/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

CGFloat static cameraPickerToolbarHeight = 44.0f;

#import "ImagePickerCircleOverlay.h"
#import <QuartzCore/QuartzCore.h>

@implementation ImagePickerCircleOverlay

- (void)drawRect:(CGRect)rect
{
    [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] setFill];
    UIRectFill(rect);
    
    CGRect holeRect = CGRectMake(rect.size.width / 2.0f - kImageCroppedWidth / 2.0f,
                                 rect.size.height / 2.0f - kImageCroppedWidth / 2.0f - cameraPickerToolbarHeight / 2.0f,
                                 kImageCroppedWidth,
                                 kImageCroppedWidth);
    
    [[UIColor clearColor] setFill];
    UIRectFill(holeRect);
}

@end
