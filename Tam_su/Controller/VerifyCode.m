//
//  VerifyCode.m
//  Taxi_Khu_Hoi
//
//  Created by Hung_mobilefolk on 10/17/17.
//  Copyright © 2017 Mobilefolk. All rights reserved.
//

#import "VerifyCode.h"
#import "XLForm.h"
#import <FirebaseAuth/FirebaseAuth.h>
//#import "DriverRegister.h"
#import "MainViewController.h"
#import "TabBarController.h"



NSString *const kVerifyButton = @"button";
NSString *const kVerifyCode = @"verifyCode";

@interface VerifyCode ()
@property (strong, nonatomic) FIRDatabaseReference *ref;

@end

@implementation VerifyCode
-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        [self initializeForm];
        self.ref = [[FIRDatabase database] reference];

    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self initializeForm];
    }
    return self;
}


-(void)initializeForm
{
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptor];
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@"Please put verify code you receive here"];
    section.footerTitle = @"We can add more text here to infor user";
    [form addFormSection:section];
    
    // Verify Code
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kVerifyCode rowType:XLFormRowDescriptorTypePhone title:@""];
    [row.cellConfigAtConfigure setObject:@"Verify Code" forKey:@"textField.placeholder"];
    [row.cellConfigAtConfigure setObject:@(NSTextAlignmentCenter) forKey:@"textField.textAlignment"];

    [section addFormRow:row];
 
    section = [XLFormSectionDescriptor formSectionWithTitle:@""];
    section.footerTitle = @"";
    [form addFormSection:section];
    
    // Button
    XLFormRowDescriptor * buttonRow = [XLFormRowDescriptor formRowDescriptorWithTag:kVerifyButton rowType:XLFormRowDescriptorTypeButton title:@"Verify"];
    buttonRow.action.formSelector = @selector(verifyCode);
    [section addFormRow:buttonRow];
    
    self.form = form;
    
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = false;

    self.title = @"Verification";
}

-(void) verifyCode
{
    [self showMainView];
}

-(void) showMainView
{
    NSString *verificationID = [[NSUserDefaults standardUserDefaults] stringForKey:AuthVerificationID];
    
    NSDictionary *formValues = self.form.formValues;
    NSLog(@"verify code is %@",[formValues objectForKey:kVerifyCode]);
    
    FIRAuthCredential *credential = [[FIRPhoneAuthProvider provider]
                                     credentialWithVerificationID:verificationID
                                     verificationCode:[formValues objectForKey:kVerifyCode]];
    
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRUser *user, NSError *error) {
                                  if (error) {
                                      // ...
                                      NSLog(@"sign in error %@",error);
                                      UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error happen" message:@"Your number is not right, you can try another number" preferredStyle:UIAlertControllerStyleAlert];
                                      UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                                      [alertView addAction:cancel];
                                      [self presentViewController:alertView animated:YES completion:nil];
                                      return;
                                  }
                                  else
                                  {
                                      // User successfully signed in. Get user data from the FIRUser object
                                      [self updateUserData:user];
                                      [self goToMainView];
                                  }
                                 
                              }];
}

-(void) updateUserData:(FIRUser *) user
{
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:UserName];
    NSString *userPhone = [[NSUserDefaults standardUserDefaults] objectForKey:UserPhone];
    NSDictionary *userInfo = @{UserName: userName,
                               UserPhone:userPhone,
                               UserId:user.uid
                               };
    
    [[[[[FIRDatabase database] reference] child:UserCollection] child:user.uid]
     updateChildValues:userInfo withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error) {
             NSLog(@"error with adding document %@",error);
         }else{
             NSLog(@"add user info success");
         }
         
     }];
    
}

-(void) goToMainView
{
      UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
      TabBarController *mainView = [storyboard instantiateViewControllerWithIdentifier:@"TabBarController"];
      [self.navigationController pushViewController:mainView animated:true];
}



-(void) updateUserName
{
    FIRUserProfileChangeRequest *changeRequest = [[FIRAuth auth].currentUser profileChangeRequest];
    changeRequest.displayName = [[NSUserDefaults standardUserDefaults] objectForKey:UserName];
    [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
        // ...
        if (error) {
            NSLog(@"have error when update user data, Firebase User");
        }
        else
        {
            NSLog(@"update user success");
        }
    }];
}


-(void) signOutUser
{
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
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
