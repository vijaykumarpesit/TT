//
//  ViewController.m
//  GoIbibo
//
//  Created by Vijay on 22/09/15.
//  Copyright © 2015 Vijay. All rights reserved.
//

#import "GoHomeViewController.h"
#import "GoLayoutHandler.h"
#import "GoBusListViewController.h"
#import "GoUserModelManager.h"
#import "GoUser.h"
#import "GoSearchPlaceViewController.h"
#import "GoNotifyMeViewController.h"

@interface GoHomeViewController ()

@property (nonatomic, strong) NSMutableDictionary *eventsByDate;
@property (nonatomic, strong) NSDate *todayDate;
@property (nonatomic, strong) NSDate *minDate;
@property (nonatomic, strong) NSDate *maxDate;
@property (nonatomic, strong) NSDate *dateSelected;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UIView *sourceView;
@property (weak, nonatomic) IBOutlet UIView *destinationView;

@end

@implementation GoHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.title = @"Search Bus";
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left-side-bar-hamburger.png"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(leftBarButtonItemPressed:)];
    _calendarManager = [JTCalendarManager new];
    _calendarManager.delegate = self;
    
    // Generate random events sort by date using a dateformatter for the demonstration
    [self createRandomEvents];
    
    // Create a min and max date for limit the calendar, optional
    [self createMinAndMaxDate];
    
    [_calendarManager setMenuView:_calendarMenuView];
    [_calendarManager setContentView:_calendarContentView];
    [_calendarManager setDate:_todayDate];

    [self didChangeModeTouch];
    
    [self configureAndAddTapGestureToView:self.sourceView andSelector:@selector(sourceViewTapped:)];
    self.sourceView.userInteractionEnabled = YES;
    [self configureAndAddTapGestureToView:self.destinationView andSelector:@selector(destinationViewTapped:)];
    self.destinationView.userInteractionEnabled = YES;
    [self configureAndAddTapGestureToView:self.searchBusesLabel andSelector:@selector(searchBusesLabelTapped:)];
    self.searchBusesLabel.userInteractionEnabled = YES;
    [self configureAndAddTapGestureToView:self.assitance andSelector:@selector(assitanceLabelTapped:)];
    self.assitance.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.searchBusText.length > 0) {
        self.searchBusesLabel.text = self.searchBusText;
    }
}

- (void)configureAndAddTapGestureToView:(UIView *)view andSelector:(SEL)selector {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark - Buttons callback

- (IBAction)didGoTodayTouch
{
    [_calendarManager setDate:_todayDate];
}

- (IBAction)didChangeModeTouch
{
    _calendarManager.settings.weekModeEnabled = !_calendarManager.settings.weekModeEnabled;
    [_calendarManager reload];
    
    CGFloat newHeight = 300;
    [self.view bringSubviewToFront:self.overlayView];
    self.overlayView.userInteractionEnabled = NO;
    self.overlayView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    if(_calendarManager.settings.weekModeEnabled){
        newHeight = 85.;
        self.overlayView.backgroundColor = [UIColor clearColor];
        [self.view sendSubviewToBack:self.overlayView];
        self.overlayView.userInteractionEnabled = YES;
    }
    [UIView animateWithDuration:0.2f animations:^{
        self.calendarContentViewHeight.constant = newHeight;
        [self.view layoutIfNeeded];
    }];
}

- (void)sourceViewTapped:(id)sender {
    [self presentSearchPlaceViewControllerIsForSourcePlace:YES];
}

- (void)presentSearchPlaceViewControllerIsForSourcePlace:(BOOL)isSourcePlace {
    GoSearchPlaceViewController *gosearchPlaceViewController = [[GoSearchPlaceViewController alloc] initWithNibName:@"GoSearchPlaceViewController" bundle:nil];
    gosearchPlaceViewController.isSourcePlace = isSourcePlace;
    gosearchPlaceViewController.updateSelectedPlace = ^void(NSString *selectedPlace){
        if (selectedPlace) {
            if (isSourcePlace) {
                ((UILabel *)[[self.sourceView subviews] objectAtIndex:2]).attributedText = [[NSAttributedString alloc] initWithString:selectedPlace attributes:nil];
            } else {
                ((UILabel *)[[self.destinationView subviews] objectAtIndex:2]).attributedText = [[NSAttributedString alloc] initWithString:selectedPlace attributes:nil];
            }
        }
    };
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:gosearchPlaceViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}
- (void)destinationViewTapped:(id)sender {
    [self presentSearchPlaceViewControllerIsForSourcePlace:NO];
}

- (void)searchBusesLabelTapped:(id)sender {
    NSString *source = [[self.sourceView.subviews objectAtIndex:2] attributedText].string.lowercaseString;
    NSString *destination = [[self.destinationView.subviews objectAtIndex:2] attributedText].string.lowercaseString;
    self.dateSelected = (_dateSelected ? _dateSelected : _todayDate);
    NSString *alertControllerTitle = nil;
    NSString *alertControllerMessaage = nil;
    if ([source isEqualToString:@"source"]) {
        alertControllerTitle = @"Source Place Not Set";
        alertControllerMessaage = @"Please select the source of the journey";
    } else if ([destination isEqualToString:@"destination"]) {
        alertControllerTitle = @"Destination Place Not Set";
        alertControllerMessaage = @"Please select the destination of the journey";
    } else if ([source isEqualToString:destination]) {
        alertControllerTitle = @"Same Destination";
        alertControllerMessaage = @"Please set the proper source/destination";
    }
    
    if (alertControllerTitle) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertControllerTitle message:alertControllerMessaage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    } else {
        if ([self.searchBusesLabel.text isEqualToString:@"Courier Services"] || [self.searchBusesLabel.text isEqualToString:@"Long Weekend Plan"]) {
            self.homeCompletionBlock(destination, source, self.dateSelected);
            [self.navigationController popToRootViewControllerAnimated:YES];
            return;
        }

        GoBusListViewController *vc = [[GoBusListViewController alloc] initWithSource:source destination:destination departureDate:(_dateSelected ? _dateSelected : _todayDate) arrivalDate:nil];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)assitanceLabelTapped:(id)sender
{
    GoNotifyMeViewController *notifyMeViewController = [[GoNotifyMeViewController alloc] initWithNibName:@"GoNotifyMeViewController" bundle:nil];
    [self.navigationController pushViewController:notifyMeViewController animated:YES];
}

#pragma mark - CalendarManager delegate

// Exemple of implementation of prepareDayView method
// Used to customize the appearance of dayView
- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(JTCalendarDayView *)dayView
{
    // Today
    if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor whiteColor];
        dayView.dotView.backgroundColor = [UIColor colorWithWhite:0.4f alpha:0.3f];
        dayView.textLabel.textColor = [UIColor colorWithRed:1.0f green:(130.0f/255.0f) blue:(125.0f/255.0f) alpha:1.0f];
    }
    // Selected date
    else if(_dateSelected && [_calendarManager.dateHelper date:_dateSelected isTheSameDayThan:dayView.date]){
        dayView.circleView.hidden = NO;
        dayView.circleView.backgroundColor = [UIColor redColor];
        dayView.dotView.backgroundColor = [UIColor whiteColor];
        dayView.textLabel.textColor = [UIColor whiteColor];
    }
    // Other month
    else if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [UIColor redColor];
        dayView.textLabel.textColor = [UIColor colorWithWhite:1.0f alpha:0.4f];
    }
    // Another day of the current month
    else{
        dayView.circleView.hidden = YES;
        dayView.dotView.backgroundColor = [UIColor redColor];
        dayView.textLabel.textColor = [UIColor blackColor];
    }
    
    if([self haveEventForDay:dayView.date]){
        dayView.dotView.hidden = NO;
    }
    else{
        dayView.dotView.hidden = YES;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(JTCalendarDayView *)dayView
{
    _dateSelected = dayView.date;
    
    // Animation for the circleView
    dayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
    [UIView transitionWithView:dayView
                      duration:.3
                       options:0
                    animations:^{
                        dayView.circleView.transform = CGAffineTransformIdentity;
                        [_calendarManager reload];
                    } completion:nil];
    
    
    // Load the previous or next page if touch a day from another month
    
    if(![_calendarManager.dateHelper date:_calendarContentView.date isTheSameMonthThan:dayView.date]){
        if([_calendarContentView.date compare:dayView.date] == NSOrderedAscending){
            [_calendarContentView loadNextPageWithAnimation];
        }
        else{
            [_calendarContentView loadPreviousPageWithAnimation];
        }
    }
}

#pragma mark - CalendarManager delegate - Page mangement

// Used to limit the date for the calendar, optional
- (BOOL)calendar:(JTCalendarManager *)calendar canDisplayPageWithDate:(NSDate *)date
{
    return [_calendarManager.dateHelper date:date isEqualOrAfter:_minDate andEqualOrBefore:_maxDate];
}

- (void)calendarDidLoadNextPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Next page loaded");
}

- (void)calendarDidLoadPreviousPage:(JTCalendarManager *)calendar
{
    //    NSLog(@"Previous page loaded");
}

#pragma mark - Fake data

- (void)createMinAndMaxDate
{
    _todayDate = [NSDate date];
    
    // Min date will be 2 month before today
    _minDate = [_calendarManager.dateHelper addToDate:_todayDate months:-2];
    
    // Max date will be 2 month after today
    _maxDate = [_calendarManager.dateHelper addToDate:_todayDate months:2];
}

// Used only to have a key for _eventsByDate
- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (BOOL)haveEventForDay:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    
    if(_eventsByDate[key] && [_eventsByDate[key] count] > 0){
        return YES;
    }
    
    return NO;
    
}

- (void)createRandomEvents
{
    _eventsByDate = [NSMutableDictionary new];
    
    for(int i = 0; i < 30; ++i){
        // Generate 30 random dates between now and 60 days later
        NSDate *randomDate = [NSDate dateWithTimeInterval:(rand() % (3600 * 24 * 60)) sinceDate:[NSDate date]];
        
        // Use the date as key for eventsByDate
        NSString *key = [[self dateFormatter] stringFromDate:randomDate];
        
        if(!_eventsByDate[key]){
            _eventsByDate[key] = [NSMutableArray new];
        }
        
        [_eventsByDate[key] addObject:randomDate];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)leftBarButtonItemPressed:(id)sender {
    [[[GoLayoutHandler sharedInstance] sideMenu] presentLeftMenuViewController];
}

-(void)digitsAuthenticationFinishedWithSession:(DGTSession *)aSession error:(NSError *)error {
    
    GoUser *user = [[GoUserModelManager sharedManager] currentUser];
    NSMutableString *phoneNo = [NSMutableString stringWithString:aSession.phoneNumber];
    user.phoneNumber =  [phoneNo substringFromIndex:3];
    user.userID = aSession.userID;
    [user saveUser];
}

@end
