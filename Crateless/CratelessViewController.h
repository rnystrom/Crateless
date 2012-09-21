//
//  CratelessViewController.h
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@interface CratelessViewController : UIViewController
<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SettingsViewControllerDelegate>

@end
