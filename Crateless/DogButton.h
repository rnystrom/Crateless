//
//  DogImageView.h
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DogButton : UIButton

@property (strong, nonatomic) Dog *dog;
@property (strong, nonatomic) UILabel *nameLabel;

- (void)reset;

@end