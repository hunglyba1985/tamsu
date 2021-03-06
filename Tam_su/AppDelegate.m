//
//  AppDelegate.m
//  Tam_su
//
//  Created by MacOS on 3/7/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "AppDelegate.h"
@import Firebase;
@import FirebaseAuth;
#import "MainViewController.h"
#import "UserRegister.h"
#import "TabBarController.h"



#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

UIBackgroundTaskIdentifier  bgTask;

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@property (strong, nonatomic) FIRDatabaseReference *ref;
// Instance member of our background task process

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Use Firebase library to configure APIs
    [FIRApp configure];

    [self checkUserSignIn];

    
    // [START set_messaging_delegate]
    [FIRMessaging messaging].delegate = self;
    // [END set_messaging_delegate]
    
    
    self.ref = [[FIRDatabase database] reference];

    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes =
        (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        // For iOS 10 display notification (sent via APNS)
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
        UNAuthorizationOptions authOptions =
        UNAuthorizationOptionAlert
        | UNAuthorizationOptionSound
        | UNAuthorizationOptionBadge;
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
        }];
#endif
    }
    
    [application registerForRemoteNotifications];
    
    return YES;
}

-(void) checkUserSignIn
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if ([FIRAuth auth].currentUser) {
        // User is signed in.
        // ...
        NSLog(@"user signed in-------");
//        NSLog(@"get current user is %@",[FIRAuth auth].currentUser.phoneNumber);
        //  TODO: Start observe myself to know what change
        [[ObserveMyself shareInstance] startObserve];
        
        TabBarController *mainView = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:mainView];
        self.window.rootViewController  = nav;
        
//        FIRUser *user = [FIRAuth auth].currentUser;
//        FIRFirestore *defaultFirestore = [FIRFirestore firestore];
//        FIRDocumentReference *docRef= [[defaultFirestore collectionWithPath:UserCollectionData] documentWithPath:user.uid];
//        [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot *snapshot, NSError *error) {
//            if (snapshot.exists) {
//                NSLog(@"App delegate Document data: %@", snapshot.data);
//                NSDictionary *userProfile = snapshot.data;
//                User *currentUser = [[User alloc] initWithData:userProfile];
//                [LocationMode shareInstance].currentUserProfile = currentUser;
//            } else {
//                NSLog(@"Document does not exist");
//            }
//        }];
        
    } else {
        // No user is signed in.
        // ...
        NSLog(@"no user signed in");
        UserRegister *welcomeView = [storyboard instantiateViewControllerWithIdentifier:@"UserRegister"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcomeView];
        self.window.rootViewController = nav;
    }
    [self.window makeKeyAndVisible];
    
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

UIBackgroundTaskIdentifier bgTask;

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"=== DID ENTER BACKGROUND ===");
    bgTask = [[UIApplication  sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"End of tolerate time. Application should be suspended now if we do not ask more 'tolerance'");
        // [self askToRunMoreBackgroundTask]; This code seems to be unnecessary. I'll verify it.
    }];
    
    if (bgTask == UIBackgroundTaskInvalid) {
        NSLog(@"This application does not support background mode");
    } else {
        //if application supports background mode, we'll see this log.
        NSLog(@"Application will continue to run in background");
//        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countHowTime) userInfo:nil repeats:YES];
        if ([FIRAuth auth].currentUser){
            NSDictionary *userActive = @{UserActive:Inactive};
            [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid]
             updateChildValues:userActive withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                 if (error) {
                     NSLog(@"error with adding document %@",error);
                 }else{
                     NSLog(@"applicationDidEnterBackground update user status success");
                 }
                 
             }];
        }
    }
    
    
    
    
   
}




- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if ([FIRAuth auth].currentUser){
        NSDictionary *userActive = @{UserActive:Active};
        [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid]
         updateChildValues:userActive withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"applicationDidBecomeActive update user status success");
             }
         }];
    }
  
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    if ([FIRAuth auth].currentUser){
        NSDictionary *userInactive = @{UserActive:Inactive};
        [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid]
         updateChildValues:userInactive withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"update user status");
             }
             
         }];
    }
}


#pragma mark - UNUserNotificationCenterDelegate
// [START ios_10_message_handling]
// Receive displayed notifications for iOS 10 devices.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSDictionary *userInfo = notification.request.content.userInfo;
    
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    
    // Print message ID.
//    if (userInfo[kGCMMessageIDKey]) {
//        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
//    }
    
    // Print full message.
    NSLog(@"%@", userInfo);
    
    // Change this to your preferred presentation option
    completionHandler(UNNotificationPresentationOptionNone);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
#if defined(__IPHONE_11_0)
         withCompletionHandler:(void(^)(void))completionHandler {
#else
withCompletionHandler:(void(^)())completionHandler {
#endif
    NSDictionary *userInfo = response.notification.request.content.userInfo;
//    if (userInfo[kGCMMessageIDKey]) {
//        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
//    }
    
    // Print full message.
    NSLog(@" userNotificationCenter didReceiveNotificationResponse %@", userInfo);
    NSLog(@"get notification category is %@",userInfo[NotificationCategory]);
    NSLog(@"get notification sender id %@",userInfo[NotificationSenderId]);
    if ([userInfo[NotificationCategory] isEqualToString:NotificationTypeMessage]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationTypeMessage object:nil userInfo:userInfo];
    }
    
    
    
    completionHandler();
}
#endif
    // [END ios_10_message_handling]
    
#pragma mark Old method to get Notification
    // [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
        
        // Print message ID.
//        if (userInfo[kGCMMessageIDKey]) {
//            NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
//        }
        
        // Print full message.
        NSLog(@"didReceiveRemoteNotification %@", userInfo);
    }
    
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // [[FIRMessaging messaging] appDidReceiveMessage:userInfo];
    
    // Print message ID.
//    if (userInfo[kGCMMessageIDKey]) {
//        NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
//    }
    
    // Print full message.
    NSLog(@"didReceiveRemoteNotification fetchCompletionHandler %@", userInfo);
    
    completionHandler(UIBackgroundFetchResultNewData);
}
    // [END receive_message]

#pragma mark FIRMessagingDelegate
// [START refresh_token]
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    NSLog(@"FCM registration token: %@", fcmToken);
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:fcmToken forKey:UserNotificationToken];
    
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
  
}
// [END refresh_token]

// [START ios_10_data_message]
// Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
// To enable direct data messages, you can set [Messaging messaging].shouldEstablishDirectChannel to YES.
- (void)messaging:(FIRMessaging *)messaging didReceiveMessage:(FIRMessagingRemoteMessage *)remoteMessage {
    NSLog(@"Received data message: %@", remoteMessage.appData);
}
// [END ios_10_data_message]

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Unable to register for remote notifications: %@", error);
}

// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs device token can be paired to
// the FCM registration token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APNs device token retrieved: %@", deviceToken);
    
    // With swizzling disabled you must set the APNs device token here.
     [FIRMessaging messaging].APNSToken = deviceToken;
}



@end
