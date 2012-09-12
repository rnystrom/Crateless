//
//  Dog.h
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Dog : NSObject

+ (Dog*)sharedInstance;

@property (copy, nonatomic, readwrite) NSString *name;
@property (strong, nonatomic, readwrite) NSDate *birthDate;
@property (strong, nonatomic, readwrite) UIImage *image;
@property (strong, nonatomic, readwrite) NSDate *lastCratedDate;
@property (assign, nonatomic, readwrite) BOOL isCrated;
@property (strong, nonatomic, readwrite) NSDateFormatter *dateFormatter;
@property (strong, nonatomic, readwrite) UILocalNotification *notification;

- (NSString*)latestError;
- (BOOL)exists;
- (BOOL)isValid;
- (NSTimeInterval)maxTimeInCrate;
- (void)sync;
- (void)crate;
- (void)uncrate;

@end
