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
//@property (assign, nonatomic) BOOL isCrated;
@property (strong, nonatomic) UILabel *countdownLabel;

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

    }
    else {
        Dog *dog = [Dog sharedInstance];
        
        [dog setName:[[self nameTextField] text]];
        [dog setBirthDate:[self selectedDate]];
        [dog setImage:[self selectedImage]];
        
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
        // FIXME: use a UIImage
        UIImageView *crateView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"crate"]];
        [crateView setBackgroundColor:[UIColor redColor]];
        [crateView setOpaque:NO];
        [self setCrateView:crateView];
        [[self view] insertSubview:[self crateView] belowSubview:[self toolBar]];
    }

    if (! [self imagePickerButton]) {
        DogButton *imagePicker = [[DogButton alloc] initWithFrame:CGRectMake(0, 0, kImageButtonWidth, kImageButtonHeight)];
        [imagePicker setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
        [imagePicker addTarget:self action:@selector(onImageButton:) forControlEvents:UIControlEventTouchUpInside];
        [self setImagePickerButton:imagePicker];
        [[self view] insertSubview:[self imagePickerButton] belowSubview:[self toolBar]];
    }
    
    if (! [self nameTextField]) {
        CGRect nameFrame = CGRectMake(0, 0, kTextFieldWidth, kTextFieldHeight);
        UITextField *nameField = [[UITextField alloc] initWithFrame:nameFrame];
        [nameField setBorderStyle:UITextBorderStyleNone];
        [nameField setPlaceholder:@"Name"];
        [nameField setBackgroundColor:[UIColor whiteColor]];
        [nameField setDelegate:self];
        [self setNameTextField:nameField];
        [[self view] addSubview:[self nameTextField]];
    }

    if (! [self dateButton]) {
        CGRect dateFrame = CGRectMake(0, 0, kTextFieldWidth, kTextFieldHeight);
        UIButton *dateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [dateButton setFrame:dateFrame];
        [dateButton setTitle:@"Birthday" forState:UIControlStateNormal];
        [dateButton addTarget:self action:@selector(onDateButton:) forControlEvents:UIControlEventTouchUpInside];
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
    CGFloat screenWidth = [[self view] frame].size.width;
    CGFloat toolbarHeight = [[self toolBar] frame].size.height;
    CGFloat workableSpace = [[self view] frame].size.height - toolbarHeight;
    CGFloat requiredSpace = kImageButtonHeight + kTextFieldHeight * 2.0f;
    CGFloat itemPadding = (workableSpace - requiredSpace) / 3.0f;
    CGFloat imageElasticHeight = toolbarHeight / 2.0f + itemPadding + kImageButtonHeight / 2.0f;
    CGFloat nameTextFieldElasticHeight = imageElasticHeight + itemPadding + kImageButtonHeight / 2.0f;
    CGFloat dateTextFieldElasticHeight = nameTextFieldElasticHeight + itemPadding + kImageButtonHeight / 2.0f;
    
    originalImage.center = CGPointMake(screenWidth / 2.0f, imageElasticHeight);
    originalNameTextField.center = CGPointMake(screenWidth / 2.0f, nameTextFieldElasticHeight);
    originalDateButton.center = CGPointMake(screenWidth / 2.0f, dateTextFieldElasticHeight);
    
    createdImage.center = CGPointMake(screenWidth / 2.0f, 330.0f);
    createdCrate = originalImage;
    
    offscreenCrateCenter = CGPointMake(screenWidth + [[self crateView] frame].size.width / 2.0f, createdCrate.center.y);
    offscreenCrateDoorCenter = CGPointMake(offscreenCrateCenter.x + screenWidth / 2.0f, offscreenCrateCenter.y);
    crateDoorCenter = CGPointMake(createdCrate.center.x + [[self crateDoorView] frame].size.width / 2.0f, createdCrate.center.y);
}

- (void)setupCreateView
{
    [[self imagePickerButton] setCenter:originalImage.center];
    [[self nameTextField] setCenter:originalNameTextField.center];
    [[self dateButton] setCenter:originalDateButton.center];
    [[self crateView] setCenter:offscreenCrateCenter];
    [[self crateDoorView] setCenter:offscreenCrateDoorCenter];
    
    originalImage.frame = [[self imagePickerButton] frame];
    originalNameTextField.frame = [[self nameTextField] frame];
    originalDateButton.frame = [[self dateButton] frame];
}

- (void)setupCrateView
{
    Dog *dog = [Dog sharedInstance];
    if ([dog isCrated]) {
        [self updateCountdownLabel];
        
        CGRect imageFrame = [[self imagePickerButton] frame];
        imageFrame.size.width = kCrateWidth;
        imageFrame.size.height = kCrateHeight;
        [[self imagePickerButton] setFrame:imageFrame];
        [[self imagePickerButton] setCenter:createdCrate.center];
    }
    else {
        [[self imagePickerButton] setCenter:createdImage.center];
    }
    
    [[self crateView] setCenter:createdCrate.center];
    [[self crateDoorView] setCenter:crateDoorCenter];
    
    [[self imagePickerButton] setDogImage:[dog image]];
    
    [[self nameTextField] removeFromSuperview];
    [[self dateButton] removeFromSuperview];
    [self setNameTextField:nil];
    [self setDateButton:nil];
    
    originalImage.frame = [[self imagePickerButton] frame];
    originalNameTextField.frame = [[self nameTextField] frame];
    originalDateButton.frame = [[self dateButton] frame];
    
    [self removeRightButtonFromToolbar];
    
    [self openCrateAndGrowDog];
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
    
    [self removeRightButtonFromToolbar];
}

- (void)transitionToCreateView
{
    
}

#pragma mark - Animations - Block returns

- (void)dropImageDown
{
    CGRect newFrame = originalImage.frame;
    newFrame.origin.y += 200.0f;
    
    [UIView animateWithDuration:kDropDuration animations:^{
        [[self imagePickerButton] setFrame:newFrame];
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
    
    CGFloat toolBarHeight = [[self toolBar] frame].size.height;
    CGFloat workableSpace = [[self view] frame].size.height - toolBarHeight - height;
    CGFloat requiredSpace = kTextFieldHeight * 2.0f;
    CGFloat itemPadding = (workableSpace - requiredSpace) / 2.0f;
    CGFloat newNameY = toolBarHeight / 2.0f + itemPadding + kTextFieldHeight / 2.0f;
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
            CGFloat hours = floorf(timeRemainingInCrate / (60.0f * 60.0f));
            CGFloat minutes = floorf((timeRemainingInCrate - hours * 60.0f) / 60.0f);
            CGFloat seconds = floorf(timeRemainingInCrate - minutes * 60.0f);
            
            if (hours < 10.0f) {
                [timeFormat appendString:@"0"];
            }
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
            [timeFormat appendString:@"00:00:00"];
        }
        
        if ([self countdownLabel]) {
            [[self countdownLabel] setText:timeFormat];
        }
        else {
            UILabel *countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, kCountdownFontSize)];
            [countdownLabel setText:timeFormat];
            [countdownLabel setFont:[UIFont systemFontOfSize:kCountdownFontSize]];
            [countdownLabel setTextColor:[UIColor whiteColor]];
            [countdownLabel setTextAlignment:UITextAlignmentCenter];
            [countdownLabel setCenter:createdImage.center];
            [countdownLabel setBackgroundColor:[UIColor clearColor]];
            [self setCountdownLabel:countdownLabel];
            [[self view] addSubview:[self countdownLabel]];
        }
        
        if (timeRemainingInCrate > 0.0f) {
            [self performSelector:@selector(updateCountdownLabel) withObject:nil afterDelay:kCountdownLabelUpdateDuration];
        }
    }
    else {
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
    CGRect imageFrame = [[self imagePickerButton] frame];
    imageFrame.size.width = kCrateWidth;
    imageFrame.size.height = kCrateHeight;
    CGPoint retainCenter = [[self imagePickerButton] center];
    
    [UIView animateWithDuration:kCrateDoorAnimationDuration
                          delay:0
                        options:UIViewAnimationCurveEaseIn
                     animations:^{
                         [[self imagePickerButton] setFrame:imageFrame];
                         [[self imagePickerButton] setCenter:retainCenter];
                     }
                     completion:^(BOOL finished){
                         if (block) {
                             block();
                         }
                     }];
}

- (void)removeRightButtonFromToolbar
{
    NSMutableArray *mutableToolbarItems = [[[self toolBar] items] mutableCopy];
    [mutableToolbarItems removeObject:[self rightButton]];
    [[self toolBar] setItems:mutableToolbarItems];
}

#pragma mark - Actions - Create view

- (void)onImageButton:(id)sender
{
    if (! [self isCrateMode]) {
        [[self nameTextField] resignFirstResponder];
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [picker setDelegate:self];
        
        ImagePickerCircleOverlay *overlay = [[ImagePickerCircleOverlay alloc] initWithFrame:[[picker view] frame]];
        [overlay setBackgroundColor:[UIColor clearColor]];
        [picker setCameraOverlayView:overlay];
        
        [self presentModalViewController:picker animated:YES];
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
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CGSize imageSize = [selectedImage size];
    CGSize pickerSize = [[picker view] frame].size;
    CGSize imageButtonSize = originalImage.frame.size;
    CGFloat resizeScale = kImageCroppedWidth / pickerSize.width;
    CGFloat scaledImageCroppedWidth = imageSize.width * resizeScale;
    
    // reversed x + y because we are in portrait
    CGRect cropRect = CGRectMake(imageSize.height / 2.0f - scaledImageCroppedWidth / 2.0f,
                                 imageSize.width / 2.0f - scaledImageCroppedWidth / 2.0f,
                                 scaledImageCroppedWidth,
                                 scaledImageCroppedWidth);
    UIImage *croppedImage = [selectedImage crop:cropRect];
    UIImage *resizedImage = [croppedImage resize:imageButtonSize];
    
    [self setSelectedImage:resizedImage];
    [[self imagePickerButton] setDogImage:[self selectedImage]];
    
    [picker dismissModalViewControllerAnimated:YES];
}

@end
