//
//  MainViewController.m
//  Tam_su
//
//  Created by MacOS on 3/7/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Main view";
    self.ref = [[FIRDatabase database] reference];
    [self addData];
    
}


-(void) addData{
    
    
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:UserName];
    NSString *userPhone = [[NSUserDefaults standardUserDefaults] objectForKey:UserPhone];
    
    NSDictionary *userInfo = @{UserName: userName,
                               UserPhone:userPhone
                               };
    
    [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid]
     setValue:userInfo withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error) {
             NSLog(@"error with adding document %@",error);
         }else{
             NSLog(@"add data success");
         }
         
     }];
    
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
