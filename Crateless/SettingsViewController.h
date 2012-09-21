//
//  SettingsViewController.h
//  Crateless
//
//  Created by Ryan Nystrom on 9/19/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@protocol SettingsViewControllerDelegate <NSObject>

@required
-(void)viewControllerShouldDismiss:(id)sender;
-(void)shouldResetView:(id)sender;

@end

@interface SettingsViewController : UITableViewController
<UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak) NSObject <SettingsViewControllerDelegate> *delegate;

@end
