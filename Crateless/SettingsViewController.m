//
//  SettingsViewController.m
//  Crateless
//
//  Created by Ryan Nystrom on 9/19/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

- (IBAction)onDone:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *notificationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthdateLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.notificationSwitch setOn:[defaults boolForKey:@"canSendNotifications"] animated:NO];
    
    Dog *dog = [Dog sharedInstance];
    self.nameLabel.text = dog.name;
    self.birthdateLabel.text = [dog birthDateString];
    self.ageLabel.text = [dog ageString];
    self.versionLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onDone:(id)sender {
    if (self.delegate) {
        [self.delegate viewControllerShouldDismiss:self];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1  && indexPath.row == 1) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure you want to reset your puppy?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [av show];
    }
    else if (indexPath.section == 2) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setMessageBody:@"" isHTML:NO];
        [controller setToRecipients:[NSArray arrayWithObject:@"rnystrom@whoisryannystrom.com"]];
        [controller setSubject:@"Crateless Question"];
        [self presentModalViewController:controller animated:YES];
    }
}

- (IBAction)onNotificationSwitch:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.notificationSwitch.isOn forKey:@"canSendNotifications"];
    [defaults synchronize];
}

#pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"] && self.delegate) {
        [self.delegate shouldResetView:self];
    }
}

#pragma mark - Mail

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (error) {
        NSLog(@"error: %@",error.localizedDescription);
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [self setNotificationSwitch:nil];
    [self setNameLabel:nil];
    [self setBirthdateLabel:nil];
    [self setAgeLabel:nil];
    [self setVersionLabel:nil];
    [super viewDidUnload];
}
@end
