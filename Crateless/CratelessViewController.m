//
//  CratelessViewController.m
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CratelessViewController.h"
#import "DogButton.h"
#import "ImagePickerCircleOverlay.h"

@interface CratelessViewController ()

//create properties
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UIButton *dateButton;
@property (strong, nonatomic) NSDate *selectedDate;
@property (strong, nonatomic) UIImage *selectedImage;
@property (assign, nonatomic) BOOL isEditing;
@property (strong, nonatomic) UIDatePicker *datePicker;

//crate properties
@property (strong, nonatomic) DogButton *imagePickerButton;
@property (strong, nonatomic) UIImageView *crateView;
@property (strong, nonatomic) UIImageView *crateDoorView;
@property (assign, nonatomic) BOOL isCrateMode;
@property (strong, nonatomic) UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

//nib
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UILabel *leftToolbarLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightToolbarLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

- (IBAction)onRightButton:(id)sender;

@end

@implementation CratelessViewController
{
    // create ivars
    CGOriginal originalImage;
    CGOriginal originalNameTextField;
    CGOriginal originalDateButton;
    CGOriginal createdImage;
    CGOriginal createdCrate;
    CGPoint offscreenCrateCenter;
    CGPoint offscreenCrateDoorCenter;
    CGPoint crateDoorCenter;
    
    // crate ivars
    CGPoint lastTouchPoint;
    UIPanGestureRecognizer *panGesture;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    lastTouchPoint = CGPointZero;
    [self setIsEditing:NO];
    
    [self setupViews];
    
    Dog *dog = [Dog sharedInstance];
    [self setIsCrateMode:[dog exists]];
    if ([self isCrateMode]) {
        [self setupCrateView];
    }
    else {
        [self setupCreateView];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    Dog *dog = [Dog sharedInstance];
    if ([self isCrateMode] && ! [dog isCrated]) {
        [self openCrateAndGrowDog];
    }
}

- (void)viewDidUnload
{
    [self setRightButton:nil];
    [self setToolBar:nil];
    [self setView:nil];
    [self setLeftToolbarLabel:nil];
    [self setRightToolbarLabel:nil];
    [self setBackgroundView:nil];
    [self setTimeLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - NIB

- (IBAction)onRightButton:(id)sender
{
    if ([self isCrateMode]) {
        UINavigationController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"Settings"];
        controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        
        SettingsViewController *settings = controller.viewControllers[0];
        settings.delegate = self;
        
        [self presentModalViewController:controller animated:YES];
    }
    else {
        Dog *dog = [Dog sharedInstance];
        
        [dog setName:[[self nameTextField] text]];
        [dog setBirthDate:[self selectedDate]];
        
        if ([dog isValid]) {
            [dog sync];
            [self setIsCrateMode:YES];
            [self transitionToCrateView];
        }
        else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" message:[dog latestError] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [av show];
        }
    }
}

#pragma mark - View state setup

- (void)setupViews
{
    if (! [self crateView]) {
        UIImageView *crateView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"crate"]];
        [crateView setOpaque:NO];
        crateView.layer.shadowColor = [UIColor blackColor].CGColor;
        crateView.layer.shadowOffset = CGSizeZero;
        crateView.layer.shadowRadius = 7.0f;
        crateView.layer.shadowOpacity = 0.7f;
        [self setCrateView:crateView];
        [[self view] insertSubview:[self crateView] belowSubview:[self toolBar]];
    }

    if (! [self imagePickerButton]) {
        DogButton *imagePicker = [[DogButton alloc] initWithFrame:CGRectMake(0, 0, kImageButtonWidth, kImageButtonHeight)];
        [imagePicker addTarget:self action:@selector(onImageButton:) forControlEvents:UIControlEventTouchUpInside];
        [imagePicker reset];
        [self setImagePickerButton:imagePicker];
        [[self view] insertSubview:[self imagePickerButton] belowSubview:[self toolBar]];
    }
    
    UIFont *contentFont = [UIFont fontWithName:@"LucidaGrande-Bold" size:17.0f];
    UIColor *contentColor = [UIColor colorWithRed:0.274 green:0.397 blue:0.516 alpha:1.000];
    if (! [self nameTextField]) {
        CGRect nameFrame = CGRectMake(0, 0, kTextFieldWidth, kTextFieldHeight);
        UITextField *nameField = [[UITextField alloc] initWithFrame:nameFrame];
        [nameField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [nameField setBackground:[UIImage imageNamed:@"name"]];
        [nameField setBorderStyle:UITextBorderStyleNone];
        [nameField setBackgroundColor:[UIColor clearColor]];
        [nameField setDelegate:self];
        [nameField setFont:contentFont];
        [nameField setTextAlignment:NSTextAlignmentLeft];
        [nameField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [nameField setTextColor:contentColor];
        
        // hack for padding
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 74, 5)];
        nameField.leftView = paddingView;
        nameField.leftViewMode = UITextFieldViewModeAlways;
        
        [self setNameTextField:nameField];
        [[self view] addSubview:[self nameTextField]];
    }

    if (! [self dateButton]) {
        CGRect dateFrame = CGRectMake(0, 0, kTextFieldWidth, kTextFieldHeight);
        UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [dateButton setBackgroundImage:[UIImage imageNamed:@"date"] forState:UIControlStateNormal];
        [dateButton setBackgroundColor:[UIColor clearColor]];
        [dateButton setFrame:dateFrame];
        [dateButton addTarget:self action:@selector(onDateButton:) forControlEvents:UIControlEventTouchUpInside];
        [dateButton.titleLabel setFont:contentFont];
        [dateButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        dateButton.titleEdgeInsets = UIEdgeInsetsMake(0, 30.0f, 0, 0);
        [dateButton setTitleColor:contentColor forState:UIControlStateNormal];
        [self setDateButton:dateButton];
        [[self view] addSubview:[self dateButton]];
    }
    
    // insert last to make sure it is lastObject of [[self view] subviews]
    if (! [self crateDoorView]) {
        // FIXME: use a UIImage
        UIImageView *crateDoorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"door"]];
        [crateDoorView setOpaque:YES];
        [self setCrateDoorView:crateDoorView];
        [[self view] insertSubview:[self crateDoorView] belowSubview:[self toolBar]];
        
        CALayer *crateDoorLayer = [[self crateDoorView] layer];
        [crateDoorLayer setAnchorPoint:CGPointMake(1.0f, 0.5f)];
    }
    
    //maths for y of name/date textfields
    CGFloat screenWidth = [[self view] bounds].size.width;
    CGFloat screenHeight = [[self view] bounds].size.height;
    CGFloat toolbarHeight = [[self toolBar] frame].size.height;
    CGFloat workableSpace = [[self view] frame].size.height - toolbarHeight;
    CGFloat requiredSpace = kImageButtonHeight + kTextFieldHeight * 2.0f;
    CGFloat itemPadding = (workableSpace - requiredSpace) / 4.0f;
    CGFloat imageElasticHeight = toolbarHeight / 2.0f + itemPadding + kImageButtonHeight / 2.0f;
    CGFloat nameTextFieldElasticHeight = imageElasticHeight + itemPadding + kImageButtonHeight / 2.0f;
    CGFloat dateTextFieldElasticHeight = nameTextFieldElasticHeight + itemPadding + kImageButtonHeight / 2.0f;
    
    originalImage.center = CGPointMake(screenWidth / 2.0f, imageElasticHeight);
    originalNameTextField.center = CGPointMake(screenWidth / 2.0f, nameTextFieldElasticHeight);
    originalDateButton.center = CGPointMake(screenWidth / 2.0f, dateTextFieldElasticHeight);
    
    createdImage.center = CGPointMake(screenWidth / 2.0f, screenHeight / 3.0f * 2.0f);
    createdCrate = originalImage;
    
    offscreenCrateCenter = CGPointMake(screenWidth + [[self crateView] frame].size.width / 2.0f, createdCrate.center.y);
    offscreenCrateDoorCenter = CGPointMake(offscreenCrateCenter.x + screenWidth / 2.0f, offscreenCrateCenter.y);
    crateDoorCenter = CGPointMake(createdCrate.center.x + [[self crateDoorView] bounds].size.width / 2.0f, createdCrate.center.y);
    
    // set toolbar font
    UIFont *toolbarFont = self.leftToolbarLabel.font;
    self.leftToolbarLabel.font = [UIFont fontWithName:@"ThirstyScriptExtraBold" size:toolbarFont.pointSize];
    self.rightToolbarLabel.font = [UIFont fontWithName:@"ThirstyScriptExtraBold" size:toolbarFont.pointSize];
    self.rightToolbarLabel.textColor = [UIColor colorWithRed:0.998 green:0.891 blue:0.519 alpha:1.000];
    
    // set bg image if iphone 5
    if ([UIScreen mainScreen].bounds.size.height > 480) {
        CGRect frame = self.backgroundView.frame;
        frame.size.height = [UIScreen mainScreen].bounds.size.height - 20 - self.toolBar.frame.size.height;
        self.backgroundView.frame = frame;
        self.backgroundView.image = [UIImage imageNamed:@"bg-568h"];
    }
    
    // hide time label
    self.timeLabel.hidden = YES;
}

- (void)setupCreateView
{
    if (! self.imagePickerButton || ! self.nameTextField || ! self.dateButton) {
        [self setupViews];
    }
    
    self.selectedDate = nil;
    self.selectedImage = nil;
    
    CGRect imageFrame = [[self imagePickerButton] frame];
    imageFrame.size.width = kImageButtonWidth;
    imageFrame.size.height = kImageButtonHeight;
    self.imagePickerButton.frame = imageFrame;
    
    [[self imagePickerButton] setCenter:originalImage.center];
    [[self nameTextField] setCenter:originalNameTextField.center];
    [[self dateButton] setCenter:originalDateButton.center];
    [[self crateView] setCenter:offscreenCrateCenter];
    [[self crateDoorView] setCenter:offscreenCrateDoorCenter];
    
    originalImage.frame = [[self imagePickerButton] frame];
    originalNameTextField.frame = [[self nameTextField] frame];
    originalDateButton.frame = [[self dateButton] frame];
    
    if (self.countdownLabel) {
        [self.countdownLabel removeFromSuperview];
        self.countdownLabel = nil;
    }
    
    [self rightbuttonToDone];
    
    [self.dateButton setTitle:@"Puppy's Birthday" forState:UIControlStateNormal];
    self.nameTextField.text = @"Puppy's Name";
    
    // removes countdownlabel
    [self updateCountdownLabel];
}

- (void)setupCrateView
{
    if (! self.imagePickerButton || ! self.nameTextField || ! self.dateButton) {
        [self setupViews];
    }
    
    Dog *dog = [Dog sharedInstance];
    if ([dog isCrated]) {
        [self updateCountdownLabel];
        
        [[self imagePickerButton] setFrame:[self cratedImageFrame]];
        [[self imagePickerButton] setCenter:createdCrate.center];
    }
    else {
        [[self imagePickerButton] setCenter:createdImage.center];
    }
    
    [[self crateView] setCenter:createdCrate.center];
    [[self crateDoorView] setCenter:crateDoorCenter];
    
    [[self imagePickerButton] setDog:dog];
    
    [[self nameTextField] removeFromSuperview];
    [[self dateButton] removeFromSuperview];
    [self setNameTextField:nil];
    [self setDateButton:nil];
    
    originalImage.frame = [[self imagePickerButton] frame];
    originalNameTextField.frame = [[self nameTextField] frame];
    originalDateButton.frame = [[self dateButton] frame];
    
    [self rightbuttonToSettings];
    
    if ([dog isCrated]) {
        
    }
    else {
        [self openCrateAndGrowDog];
    }
    
    self.imagePickerButton.nameLabel.hidden = NO;
}

#pragma mark - Animations - Transitioning

- (void)transitionToCrateView
{
    CGFloat totalTime = 0.0f;
    if ([self isEditing]) {
        [self performSelector:@selector(endEditingCreateForm) withObject:nil afterDelay:(totalTime += kSystemItemAnimationDuration)];
    }
    [self performSelector:@selector(slideNameOffLeft) withObject:nil afterDelay:(totalTime += kSlideDuration + kTimingPadding)];
    [self performSelector:@selector(slideDateOffRight) withObject:nil afterDelay:(totalTime += kSlideDuration + kTimingPadding)];
    [self performSelector:@selector(dropImageDown) withObject:nil afterDelay:(totalTime += kDropDuration + kTimingPadding)];
    [self performSelector:@selector(slideInCrate) withObject:nil afterDelay:(totalTime += kSlideDuration + kTimingPadding)];
    [self performSelector:@selector(openCrateAndGrowDog) withObject:nil afterDelay:totalTime];
    
    [self rightbuttonToSettings];
}

- (void)transitionToCreateView
{
    [self.imagePickerButton reset];
    
    [self setupCreateView];
    
    Dog *dog = [Dog sharedInstance];
    dog.name = nil;
    dog.birthDate = nil;
    [dog sync];
}

#pragma mark - Animations - Block returns

- (void)dropImageDown
{
//    CGRect newFrame = originalImage.frame;
//    newFrame.origin.y += 200.0f;
    
    [UIView animateWithDuration:kDropDuration animations:^{
//        [[self imagePickerButton] setFrame:newFrame];
        self.imagePickerButton.center = createdImage.center;
    } completion:^(BOOL finished) {
        if (finished) {
            Dog *dog = [Dog sharedInstance];
            self.imagePickerButton.nameLabel.text = dog.name;
            self.imagePickerButton.nameLabel.hidden = NO;
        }
    }];
}

- (void)slideDateOffRight
{
    CGFloat newX = [[self view] frame].size.width;
    CGRect originalFrame = originalDateButton.frame;
    CGPoint newOrigin = CGPointMake(newX, originalFrame.origin.y);
    originalFrame.origin = newOrigin;
    
    [UIView animateWithDuration:kSlideDuration animations:^{
        [[self dateButton] setFrame:originalFrame];
    }];
}

- (void)slideNameOffLeft
{
    CGFloat newX = -1.0f * [[self nameTextField] frame].size.width;
    CGRect originalFrame = originalNameTextField.frame;
    CGPoint newOrigin = CGPointMake(newX, originalFrame.origin.y);
    originalFrame.origin = newOrigin;
    
    [UIView animateWithDuration:kSlideDuration animations:^{
        [[self nameTextField] setFrame:originalFrame];
    }];
}

- (void)slideInCrate
{
    CGPoint newCrateCenter = originalImage.center;
    [UIView animateWithDuration:kSlideDuration animations:^{
        [[self crateView] setCenter:newCrateCenter];
        [[self crateDoorView] setCenter:crateDoorCenter];
    }];
}

- (void)slideNameAndDateDown
{
    CGRect newDateFrame = [[self datePicker] frame];
    newDateFrame.origin.y = [[self view] frame].size.height;
    
    [UIView animateWithDuration:kSystemItemAnimationDuration animations:^{
        [[self datePicker] setFrame:newDateFrame];
        [[self imagePickerButton] setCenter:originalImage.center];
        [[self nameTextField] setCenter:originalNameTextField.center];
        [[self dateButton] setCenter:originalDateButton.center];
    }];
}

#pragma mark - Animations - Create view

- (void)beginEditingCreateFormWithEntryHeight:(CGFloat)height
{
    [self setIsEditing:YES];
    
    CGFloat toolBarHeight = [[self toolBar] bounds].size.height;
    CGFloat workableSpace = [[self view] bounds].size.height - toolBarHeight - height;
    CGFloat requiredSpace = kTextFieldHeight * 2.0f;
    CGFloat itemPadding = (workableSpace - requiredSpace) / 3.0f;
    CGFloat newNameY = toolBarHeight / 2.0f + 20.0f + itemPadding + kTextFieldHeight / 2.0f;
    CGFloat newDateY = newNameY + itemPadding * 2.0f + kTextFieldHeight / 2.0f;
    
    CGPoint newNameCenter = CGPointMake(originalNameTextField.center.x, newNameY);
    CGPoint newDateCenter = CGPointMake(originalDateButton.center.x, newDateY);
    
    CGFloat newImageY = -1.0f * [[self imagePickerButton] frame].size.height / 2.0f;
    CGPoint newImageCenter = CGPointMake(originalImage.center.x, newImageY);
    
    [UIView animateWithDuration:kSystemItemAnimationDuration animations:^{
        [[self imagePickerButton] setCenter:newImageCenter];
        [[self nameTextField] setCenter:newNameCenter];
        [[self dateButton] setCenter:newDateCenter];
    } completion:^(BOOL finished){
        if (finished) {

        }
    }];
}

- (void)endEditingCreateForm
{
    [self setIsEditing:NO];
    [[self nameTextField] resignFirstResponder];
    [self slideNameAndDateDown];
}

#pragma mark - Animations - Crate view

- (void)updateCountdownLabel
{
    Dog *dog = [Dog sharedInstance];
    if ([dog isCrated]) {
        NSDate *dateCrated = [dog lastCratedDate];
        NSTimeInterval timeSinceCrated = [dateCrated timeIntervalSinceNow];
        CGFloat timeRemainingInCrate = [dog maxTimeInCrate] + timeSinceCrated;  //timeSinceCrated is a negative value
        NSMutableString *timeFormat = [[NSMutableString alloc] initWithString:@""];
        
        if (timeRemainingInCrate > 0.0f) {
            CGFloat hoursf = timeRemainingInCrate / (60.0f * 60.0f);
            CGFloat hours = floorf(hoursf);
            
            CGFloat minutesf = (hoursf - hours) * 60.0f;
            CGFloat minutes = floorf(minutesf);
            
            CGFloat secondsf = (minutesf - minutes) * 60.0f;
            CGFloat seconds = floorf(secondsf);
            
//            if (hours < 10.0f) {
//                [timeFormat appendString:@"0"];
//            }
            [timeFormat appendString:[NSString stringWithFormat:@"%.0f:",hours]];
            if (minutes < 10.0f) {
                [timeFormat appendString:@"0"];
            }
            [timeFormat appendString:[NSString stringWithFormat:@"%.0f:",minutes]];
            if (seconds < 10.0f) {
                [timeFormat appendString:@"0"];
            }
            [timeFormat appendString:[NSString stringWithFormat:@"%.0f",seconds]];
        }
        else {
            [timeFormat appendString:@"0:00:00"];
        }
        
        if ([self countdownLabel]) {
            if (!self.countdownLabel.superview) {
                [self.view addSubview:self.countdownLabel];
            }
            
            [[self countdownLabel] setText:timeFormat];
        }
        else {
            UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, kCountdownFontSize)];
            [countdownLabel setText:timeFormat];
            [countdownLabel setFont:[UIFont fontWithName:@"LucidaGrande" size:60.0f]];
            [countdownLabel setTextColor:[UIColor whiteColor]];
            [countdownLabel setTextAlignment:UITextAlignmentCenter];
            [countdownLabel setCenter:createdImage.center];
            [countdownLabel setBackgroundColor:[UIColor clearColor]];
            [countdownLabel setShadowColor:[UIColor blackColor]];
            [countdownLabel setShadowOffset:CGSizeMake(0, -1)];
            [self setCountdownLabel:countdownLabel];
            [[self view] addSubview:[self countdownLabel]];
            
            self.timeLabel.hidden = NO;
            CGRect frame = self.timeLabel.frame;
            frame.origin.y = countdownLabel.frame.origin.y - 30.0f;
            self.timeLabel.frame = frame;
        }
        
        if (timeRemainingInCrate > 0.0f) {
            [self performSelector:@selector(updateCountdownLabel) withObject:nil afterDelay:kCountdownLabelUpdateDuration];
        }
    }
    else {
        self.timeLabel.hidden = YES;
        [[self countdownLabel] removeFromSuperview];
        [self setCountdownLabel:nil];
    }
}

- (void)openCrateAndGrowDog
{
    CALayer *crateDoorLayer = [[self crateDoorView] layer];
    CGFloat degrees = kCrateDoorOpenAngle;
    CGFloat radians = degrees * M_PI / 180.0f;
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = kCrateDoor3DPerspective;
    transform = CATransform3DRotate(transform, radians, 0.0f, 1.0f, 0.0f);
    
    CGRect imageFrame = [[self imagePickerButton] frame];
    imageFrame.size.width = kImageButtonWidth;
    imageFrame.size.height = kImageButtonHeight;
    
    [UIView animateWithDuration:kCrateDoorAnimationDuration
                          delay:0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                         [crateDoorLayer setTransform:transform];
                         [[self imagePickerButton] setFrame:imageFrame];
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

- (void)closeCrate
{
    CALayer *crateDoorLayer = [[self crateDoorView] layer];
    CGFloat degrees = 0.0f;
    CGFloat radians = degrees * M_PI / 180.0f;
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = kCrateDoor3DPerspective;
    transform = CATransform3DRotate(transform, radians, 0.0f, 1.0f, 0.0f);
        
    [UIView animateWithDuration:kCrateDoorAnimationDuration
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         [crateDoorLayer setTransform:transform];
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

- (void)shrinkDogWithCompletion:(void (^)())block
{
    CGPoint retainCenter = [[self imagePickerButton] center];
    
    [UIView animateWithDuration:kCrateDoorAnimationDuration
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         [[self imagePickerButton] setFrame:[self cratedImageFrame]];
                         [[self imagePickerButton] setCenter:retainCenter];
                     }
                     completion:^(BOOL finished){
                         if (block) {
                             block();
                         }
                     }];
}

- (void)rightbuttonToSettings
{
    [self.rightButton setBackgroundImage:[UIImage imageNamed:@"gear"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//    self.rightButton.image = [UIImage imageNamed:@"gear"];
    self.rightButton.title = @"";
//    self.rightButton.style = UIBarButtonItemStyleBordered;
//    NSMutableArray *mutableToolbarItems = [[[self toolBar] items] mutableCopy];
//    [mutableToolbarItems removeObject:[self rightButton]];
//    [[self toolBar] setItems:mutableToolbarItems];
}

- (void)rightbuttonToDone
{
    [self.rightButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.rightButton.title = @"Done";
//    NSMutableArray *mutableToolbarItems = [[[self toolBar] items] mutableCopy];
//    [mutableToolbarItems removeObject:[self rightButton]];
//    [[self toolBar] setItems:mutableToolbarItems];
}

#pragma mark - Actions - Create view

- (void)onImageButton:(id)sender
{
    if (! [self isCrateMode]) {
        [[self nameTextField] resignFirstResponder];
        
#if !(TARGET_IPHONE_SIMULATOR)
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [picker setDelegate:self];
        
        ImagePickerCircleOverlay *overlay = [[ImagePickerCircleOverlay alloc] initWithFrame:[[picker view] frame]];
        [overlay setBackgroundColor:[UIColor clearColor]];
        [picker setCameraOverlayView:overlay];
        
        [self presentModalViewController:picker animated:YES];
#else
        [self didSelectImage:[UIImage imageNamed:@"zoey.jpg"]];
#endif
    }
}

- (void)onDateButton:(id)sender
{
    if (! [self isEditing] || [[self nameTextField] isFirstResponder]) {
        [[self nameTextField] resignFirstResponder];
        
        if (! [self datePicker]) {
            UIDatePicker *datePicker = [[UIDatePicker alloc] init];
            [datePicker setDate:[NSDate date]];
            [datePicker addTarget:self action:@selector(onDateChanged:) forControlEvents:UIControlEventValueChanged];
            [datePicker setDatePickerMode:UIDatePickerModeDate];
            [self setDatePicker:datePicker];
            [[self view] addSubview:[self datePicker]];
        }
        
        CGRect dateFrame = [[self datePicker] frame];
        CGFloat newDatePickerY = [[self view] frame].size.height - dateFrame.size.height;
        dateFrame.origin.y = [[self view] frame].size.height;
        [[self datePicker] setFrame:dateFrame];
        
        dateFrame.origin.y = newDatePickerY;
        [UIView animateWithDuration:kSystemItemAnimationDuration animations:^{
            [[self datePicker] setFrame:dateFrame];
        }];
        [self beginEditingCreateFormWithEntryHeight:dateFrame.size.height];
    }
    else if ([self datePicker]) {
        [self endEditingCreateForm];
    }
}

- (void)onDateChanged:(id)sender
{
    if (sender == [self datePicker]) {
        Dog *dog = [Dog sharedInstance];
        NSDate *selectedDate = [[self datePicker] date];
        NSString *dateText = [[dog dateFormatter] stringFromDate:selectedDate];
        [[self dateButton] setTitle:dateText forState:UIControlStateNormal];
        [self setSelectedDate:selectedDate];
    }
}

- (void)didSelectImage:(UIImage*)image {
    CGSize imageSize = [image size];
    CGSize pickerSize = [self.view bounds].size;
    CGSize imageButtonSize = originalImage.frame.size;
    CGFloat resizeScale = kImageCroppedWidth / pickerSize.width;
    CGFloat scaledImageCroppedWidth = imageSize.width * resizeScale;
    
    // reversed x + y because we are in portrait
    CGRect cropRect = CGRectMake(imageSize.height / 2.0f - scaledImageCroppedWidth / 2.0f,
                                 imageSize.width / 2.0f - scaledImageCroppedWidth / 2.0f,
                                 scaledImageCroppedWidth,
                                 scaledImageCroppedWidth);
    UIImage *croppedImage = [image crop:cropRect];
    UIImage *resizedImage = [croppedImage resize:imageButtonSize];
    
    UIGraphicsBeginImageContextWithOptions(resizedImage.size, NO, 1.0);
    CGRect bounds = CGRectMake(0, 0, resizedImage.size.width, resizedImage.size.height);
    [[UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:resizedImage.size.height / 2.0f] addClip];
    [resizedImage drawInRect:bounds];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setSelectedImage:roundedImage];
    
    Dog *dog = [Dog sharedInstance];
    dog.image = self.selectedImage;
    
    [[self imagePickerButton] setDog:dog];
}

#pragma mark - Actions - Crate view

- (void)crate:(BOOL)shouldCrate
{
    CGPoint newCenter = CGPointZero;
    if (shouldCrate) {
        [self shrinkDogWithCompletion:^{
            [self closeCrate];
        }];
        newCenter = [[self crateView] center];
    }
    else {
        [self openCrateAndGrowDog];
        newCenter = createdImage.center;
    }
    
    Dog *dog = [Dog sharedInstance];
    if (shouldCrate != [dog isCrated]) {
        [dog setIsCrated:shouldCrate];
        
        if (shouldCrate) {
            [dog crate];
        }
        else {
            [dog uncrate];
        }
        
        // cancel so we don't build recursion
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCountdownLabel) object:nil];
        [self updateCountdownLabel];
    }
    
    [UIView animateWithDuration:kSendToCrateDuration
                          delay:0
                        options:(UIViewAnimationCurveEaseOut)
                     animations:^{
                         [[self imagePickerButton] setCenter:newCenter];
                     }
                     completion:^(BOOL finished){
                         
                     }];
}

#pragma mark - Setters

- (void)setIsCrateMode:(BOOL)isCrateMode
{
    _isCrateMode = isCrateMode;
    if (isCrateMode) {
        panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanImageButton:)];
        [panGesture setCancelsTouchesInView:YES];
        [[self imagePickerButton] addGestureRecognizer:panGesture];
    }
    else {
        [[self imagePickerButton] removeGestureRecognizer:panGesture];
    }
}

#pragma mark - Getters

- (CGRect)cratedImageFrame
{
    CGRect imageFrame = [[self imagePickerButton] frame];
    CGSize crateImageSize = [UIImage imageNamed:@"door"].size;
    imageFrame.size.height = crateImageSize.height;
    imageFrame.size.width = crateImageSize.height;
    return imageFrame;
}

#pragma mark - NSNotifications

#pragma mark - Touch handlers

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self isEditing]) {
        [self endEditingCreateForm];
    }
}

#pragma mark - Gesture recognizers

- (void)onPanImageButton:(UIPanGestureRecognizer*)recognizer
{
    // FIXME: if alert happens and we are panning, reset
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint currentTouchPoint = [recognizer locationOfTouch:0 inView:[self view]];
        lastTouchPoint = currentTouchPoint;
        
        Dog *dog = [Dog sharedInstance];
        if ([dog isCrated]) {
            [self openCrateAndGrowDog];
        }
    }
    else if ([recognizer state] == UIGestureRecognizerStateChanged) {
        CGPoint currentTouchPoint = [recognizer locationOfTouch:0 inView:[self view]];
        CGFloat xDif = currentTouchPoint.x - lastTouchPoint.x;
        CGFloat yDif = currentTouchPoint.y - lastTouchPoint.y;
        CGPoint currentCenter = [[self imagePickerButton] center];
        CGPoint newCenter = CGPointMake(currentCenter.x + xDif, currentCenter.y + yDif);
        
        [[self imagePickerButton] setCenter:newCenter];
        
        lastTouchPoint = currentTouchPoint;
    }
    else if ([recognizer state] == UIGestureRecognizerStateEnded ||
             [recognizer state] == UIGestureRecognizerStateFailed) {
        
        BOOL willCrate = CGRectContainsPoint([[self crateView] frame], lastTouchPoint);
        
        [self crate:willCrate];
        
        lastTouchPoint = CGPointZero;
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == [self nameTextField]) {
        [self beginEditingCreateFormWithEntryHeight:216.0f];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self endEditingCreateForm];
    return YES;
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissModalViewControllerAnimated:YES];
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self didSelectImage:selectedImage];
}

#pragma mark - Settings delegate

- (void)viewControllerShouldDismiss:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)shouldResetView:(id)sender {
    Dog *dog = [Dog sharedInstance];
    [dog uncrate];
    [dog reset];
    
    [self setIsCrateMode:NO];
    [self transitionToCreateView];
    [self dismissModalViewControllerAnimated:YES];
}

@end
