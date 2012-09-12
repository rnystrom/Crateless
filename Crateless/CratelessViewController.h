//
//  CratelessViewController.h
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CratelessViewController : UIViewController
<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) IBOutlet UIView *view;

- (IBAction)onRightButton:(id)sender;

@end
