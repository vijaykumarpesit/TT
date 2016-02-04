//
//  AppDelegate.m
//  GoIbibo
//
//  Created by Vijay on 22/09/15.
//  Copyright © 2015 Vijay. All rights reserved.
//

#import "AppDelegate.h"
#import "GoLayoutHandler.h"
#import <Fabric/Fabric.h>
#import <DigitsKit/DigitsKit.h>
#import <Parse/Parse.h>
#import "GoContactSync.h"
#import "GoFriendsTripDetailsController.h"
#import "RESideMenu.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [Fabric with:@[[Digits class]]];
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"uxi076jAeUCcraZcA9WyF9vHVPqTzChkyrowXPkE"
                  clientKey:@"XOoJ6M8BodHnfQP5T6yngu8lqGrC6oyWhW41Vvwd"];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self registerForREmoteNotifForApp:application];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self showHomeScreen];
    [self.window makeKeyAndVisible];
    [[GoContactSync sharedInstance] syncAddressBookIfNeeded];
    return YES;
}

- (void)registerForREmoteNotifForApp:(UIApplication *)application {
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    NSDictionary *aps = userInfo[@"aps"];
    NSString *msisdn = aps[@"alert"];
    msisdn = [msisdn substringToIndex:10];
    GoFriendsTripDetailsController *friendsTrip = [[GoFriendsTripDetailsController alloc] initWithNibName:@"GoFriendsTripDetailsController" bundle:nil];
    friendsTrip.selectedFriend = msisdn;
    [(UINavigationController *)[(RESideMenu *)self.window.rootViewController contentViewController] pushViewController:friendsTrip animated:YES];
    
}

- (void)showHomeScreen {
    //Call this whenever you want to test twitter digits login
    //[[Digits sharedInstance] logOut];
    
    self.window.rootViewController = [[GoLayoutHandler sharedInstance] sideMenu];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    //Move this to proper place

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
