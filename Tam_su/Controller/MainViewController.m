//
//  MainViewController.m
//  Tam_su
//
//  Created by MacOS on 3/7/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "MainViewController.h"
#import "ChatViewController.h"


@interface MainViewController () <UITableViewDataSource,UITableViewDelegate>
{
    NSArray *friendsList;
}
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) UITableView *tableView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Main view";
    self.ref = [[FIRDatabase database] reference];
    [self uploadUserNotificationToken];
    [self getAllUserActive];
    [self showListAllFriends];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openChatView:) name:NotificationTypeMessage object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationOnApp:) name:NotificationHaveMessageOnApp object:nil];

}

-(void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    NSLog(@"main view will disappear");
    [self.ref removeAllObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) uploadUserNotificationToken {
        NSString *userNotificationToken = [[NSUserDefaults standardUserDefaults] objectForKey:UserNotificationToken];
    if (userNotificationToken) {
        NSDictionary *userActive = @{UserNotificationToken:userNotificationToken};
        [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid]
         updateChildValues:userActive withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"uploadUserNotificationToken success");
             }
         }];
    }
}
-(void) showNotificationOnApp:(NSNotification *) notification
{
    NSDictionary *notificationInfo = notification.userInfo;
    NSString *alertStr = [NSString stringWithFormat:@"%@: %@",notificationInfo[SenderName],notificationInfo[TexMessage]];
    [JDStatusBarNotification showWithStatus:alertStr dismissAfter:2 styleName:JDStatusBarStyleSuccess];
    
}

// TODO: OPEN CHAT VIEW FROM NOTIFICAITON
-(void) openChatView:(NSNotification *) notification{
    NSLog(@"start open chat view for user when get notification %@",notification.userInfo);
    NSString *senderId = notification.userInfo[NotificationSenderId];
    NSDictionary *receiver = @{
                             UserId:senderId,
                             };
    [self showChatViewController:receiver];
}

-(void) getAllUserActive{
    
//    [[[[self.ref child:UserCollection] queryOrderedByChild:UserActive]
//      queryEqualToValue:Active]
//     observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
//         NSLog(@"get all users active");
//         if (snapshot.value != [NSNull null])
//         {
//             NSArray *allUsersActive = [snapshot.value allValues];
//             NSLog(@"number of all users active is %i",(int)allUsersActive.count);
//             NSLog(@"all user active is %@",allUsersActive);
//             friendsList = allUsersActive;
//             [self.tableView reloadData];
////             for (NSDictionary *snap in [snapshot.value allValues]) {
////                 NSLog(@"---> %@",snap);
////             }
//         }
//     }];
    
    [[self.ref child:UserCollection]
     observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
         NSLog(@"get all users active");
         if (snapshot.value != [NSNull null])
         {
             NSArray *allUsersActive = [snapshot.value allValues];
             NSLog(@"number of all users active is %i",(int)allUsersActive.count);
//             NSLog(@"all user active is %@",allUsersActive);
             friendsList = allUsersActive;
             [self.tableView reloadData];
             //             for (NSDictionary *snap in [snapshot.value allValues]) {
             //                 NSLog(@"---> %@",snap);
             //             }
         }
     }];
    
}

-(void) showListAllFriends{
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tableCell"];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    
}

#pragma mark TableViewDatasource
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return friendsList.count;
}
-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableCell" forIndexPath:indexPath];
    NSDictionary *friendInfo = [friendsList objectAtIndex:indexPath.row];
    cell.textLabel.text = friendInfo[UserName];
    
    
    return cell;
}


#pragma mark TableViewDelegate
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: We have create channel for that conversation
    // Because we will delete the conversation after attendant read it
    [self showChatViewController:[friendsList objectAtIndex:indexPath.row]];
    
}


-(void) showChatViewController:(NSDictionary *) receiver
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *chatView = [storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    chatView.receiver = receiver;
    [self.navigationController pushViewController:chatView animated:YES];
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

@end
