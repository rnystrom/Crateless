//
//  Dog.m
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import "Dog.h"

static NSString *dogNameKey = @"crateless_dogNameKey";
static NSString *dogDateKey = @"crateless_dogDateKey";
static NSString *dogImageKey = @"crateless_dogImageKey.png";
static NSString *dogLastCratedKey = @"crateless_dogLastCratedKey";
static NSString *dogIsCratedKey = @"crateless_dogIsCratedKey";
static NSString *dogNotificationKey = @"crateless_dogNotificationKey";

@implementation Dog
{
    NSString *latestError;
}

#pragma mark - Singleton

+ (Dog*)sharedInstance
{
    static dispatch_once_t onceQueue;
    static Dog *dog = nil;
    
    dispatch_once(&onceQueue, ^{ dog = [[self alloc] init]; });
    return dog;
}

#pragma mark - init

- (id)init
{
    if (self = [super init]) {
        // Wipe all defaults
        // for testing only
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _name = [defaults objectForKey:dogNameKey];
        _birthDate = [defaults objectForKey:dogDateKey];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:dogImageKey];
        _image = [UIImage imageWithContentsOfFile:path];
        
        _lastCratedDate = [defaults objectForKey:dogLastCratedKey];
        _isCrated = [defaults boolForKey:dogIsCratedKey];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterLongStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        
        NSData *notificationData = [defaults objectForKey:dogNotificationKey];
        if (notificationData) {
            _notification = [NSKeyedUnarchiver unarchiveObjectWithData:notificationData];
        }
    }
    return self;
}

#pragma mark - Public

- (BOOL)exists
{
    return [self isValid];
}

- (BOOL)isValid
{
    NSString *error = nil;
    if (! [self name]) {
        error = @"Name is required.";
    }
    if (! [self birthDate]) {
        error = @"A birthdate is required.";
    }
    if (! [self image]) {
        error = @"An image is required";
    }
    if (error) {
        latestError = error;
        return NO;
    }
    return YES;
}

- (NSString*)latestError
{
    return latestError;
}

- (NSTimeInterval)maxTimeInCrate
{
    return 10.0f;
}

- (void)sync
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[self name] forKey:dogNameKey];
        [defaults setBool:[self isCrated] forKey:dogIsCratedKey];
        [defaults setObject:[self lastCratedDate] forKey:dogLastCratedKey];
        [defaults setObject:[self birthDate] forKey:dogDateKey];
        [defaults synchronize];

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:dogImageKey];
        NSData* data = UIImagePNGRepresentation([self image]);
        [data writeToFile:path atomically:YES];
    });
}

- (void)crate
{
    [self setIsCrated:YES];
    [self setLastCratedDate:[NSDate date]];
    [self createNotification];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:[self isCrated] forKey:dogIsCratedKey];
        [defaults setObject:[self lastCratedDate] forKey:dogLastCratedKey];
        
        NSData *notificationData = [NSKeyedArchiver archivedDataWithRootObject:[self notification]];
        [defaults setObject:notificationData forKey:dogNotificationKey];
        
        [defaults synchronize];
    });
}

- (void)uncrate
{
    [self setIsCrated:NO];
    [self cancelNotification];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:[self isCrated] forKey:dogIsCratedKey];
        [defaults removeObjectForKey:dogNotificationKey];
        [defaults removeObjectForKey:dogLastCratedKey];
        
        [defaults synchronize];
    });
}

#pragma mark - Private

- (void)createNotification
{
    NSString *messageString = [NSString stringWithFormat:@"%@ has been in the crate for too long, its time to go out!",[self name]];
    
    NSDate *now = [NSDate date];
    NSDate *scheduleDate = [now dateByAddingTimeInterval:[self maxTimeInCrate]];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    [notification setTimeZone:[NSTimeZone defaultTimeZone]];
    [notification setFireDate:scheduleDate];
    [notification setAlertAction:@"Ok"];
    [notification setAlertBody:messageString];
    [notification setSoundName:UILocalNotificationDefaultSoundName];
    [notification setApplicationIconBadgeNumber:1];
    
    [self setNotification:notification];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)cancelNotification
{
    if ([self notification]) {
        [[UIApplication sharedApplication] cancelLocalNotification:[self notification]];
        [self setNotification:nil];
    }
}

#pragma mark - Setters

#pragma mark - Getters

@end