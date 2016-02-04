//
//  GoPaymentConfirmation.m
//  GoIbibo
//
//  Created by Vijay on 24/09/15.
//  Copyright © 2015 Vijay. All rights reserved.
//

#import "GoPaymentConfirmation.h"
#import "CardIO.h"
#import "GoUser.h"
#import "GoUserModelManager.h"
#import "MBProgressHUD.h"
#import "GoContactSyncEntry.h"
#import "GoContactSync.h"


@interface GoPaymentConfirmation ()<CardIOPaymentViewControllerDelegate>
@property (nonatomic, strong) GoBusDetails *busDetails;
@property (nonatomic, strong) NSDictionary *seatNoDictionary;
@property (weak, nonatomic) IBOutlet UIImageView *scanCardImageView;
@property (weak, nonatomic) IBOutlet UIImageView *netBanking;
@property (weak, nonatomic) IBOutlet UIImageView *wallets;
@end

@implementation GoPaymentConfirmation

- (instancetype)initWithBusDetails:(GoBusDetails *)busDetails withSeatNoDictionary:(NSDictionary *)seatNoDictionary;
 {
    self = [super initWithNibName:@"GoPaymentConfirmation" bundle:nil];
    if (self) {
        self.busDetails = busDetails;
        self.seatNoDictionary = seatNoDictionary;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = YES;
    [CardIOUtilities preload];
    [self configureAndAddTapGestureToView:self.scanCardImageView andSelector:@selector(scanCardClicked:)];
    self.scanCardImageView.userInteractionEnabled = YES;
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)configureAndAddTapGestureToView:(UIView *)view andSelector:(SEL)selector {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tapGestureRecognizer];
}

- (void)scanCardClicked:(id)sender {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    [self presentViewController:scanViewController animated:YES completion:nil];
    //[self userDidProvideCreditCardInfo:nil inPaymentViewController:nil];
}

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    NSLog(@"User canceled payment info");
    // Handle user cancellation here...
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    // The full card number is available as info.cardNumber, but don't log that!
    //NSLog(@"Received card info. Number: %@, expiry: %02lu/%lu, cvv: %@.", info.redactedCardNumber, (unsigned long)info.expiryMonth, (unsigned long)info.expiryYear, info.cvv);
    // Use the card info...
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
    
    PFObject *bookedBusDetails = nil;
    if (self.shouldSend) {
        bookedBusDetails = [PFObject objectWithClassName:@"BusBookingDetails"];
        bookedBusDetails[@"skey"] = self.busDetails.skey;
        bookedBusDetails[@"bookedUserPhoneNo"] = [[[GoUserModelManager sharedManager] currentUser] phoneNumber];
        NSString *dictString = [self hexStringFromDictionary:self.seatNoDictionary];
        bookedBusDetails[@"seatNoDictionary"] = dictString;
        bookedBusDetails[@"departureTime"] = self.busDetails.departureTime;
        bookedBusDetails[@"travelsName"] = self.busDetails.travelsName;
        bookedBusDetails[@"source"] = self.busDetails.source;
        bookedBusDetails[@"destination"] = self.busDetails.destination;
        bookedBusDetails[@"departureDate"] = self.busDetails.departureDate;
        
        //Push notif
        PFQuery *query = [PFQuery queryWithClassName:@"SubscribeService"];
        [query whereKey:@"source" equalTo:self.busDetails.source];
        [query whereKey:@"destination" equalTo:self.busDetails.destination];
        
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
                for (PFObject *subscription in objects) {
                    NSString *phoneNo = subscription[@"phoneNumber"];
                    GoContactSyncEntry *entry =[[[GoContactSync sharedInstance] syncedContacts] valueForKey:phoneNo];
                    if (entry) {
                        NSString *deviceToken = subscription[@"deviceToken"];
                        PFQuery *query = [PFQuery queryWithClassName:@"SubscribeService"];
                        [query whereKey:@"deviceToken" equalTo:deviceToken];
                        [PFPush sendPushMessageToQuery:query withMessage:[NSString stringWithFormat:@"%@ travel is matching with your subscription criteria",[[[GoUserModelManager sharedManager] currentUser] phoneNumber]] error:nil];
                        
                    }
                }
                
            }];
}
    MBProgressHUD *HUDView = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUDView.mode = MBProgressHUDModeIndeterminate;
    HUDView.labelText = @"Processing...";
    [bookedBusDetails saveInBackground];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        MBProgressHUD *HUDViewCompleted = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUDViewCompleted.mode = MBProgressHUDModeCustomView;
        HUDViewCompleted.labelText = @"Completed";
        HUDViewCompleted.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.navigationController popToRootViewControllerAnimated:YES];
        });
    });
}

- (NSString *) hexStringFromDictionary:(NSDictionary *)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    return [jsonData description];
}
@end
