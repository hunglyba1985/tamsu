//
//  UserRegister.m
//  Taxi_Khu_Hoi
//
//  Created by Hung_mobilefolk on 10/17/17.
//  Copyright © 2017 Mobilefolk. All rights reserved.
//

#import "UserRegister.h"
#import "XLForm.h"
#import "VerifyCode.h"
#import <FirebaseAuth/FirebaseAuth.h>
#import "TabBarController.h"


NSString *const kName = @"name";
NSString *const kNumber = @"number";
NSString *const kButton = @"button";
NSString *const kEmail = @"email";
NSString *const kPassword = @"password";
NSString *const kRegisterEmail = @"register email";

@interface UserRegister ()

@end

@implementation UserRegister

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
        [self initializeForm];
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
    XLFormSectionDescriptor * section1;

    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptor];
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@"Register with phone"];
    [form addFormSection:section];
    
    
    // Name
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kName rowType:XLFormRowDescriptorTypeText title:@"Name:"];
    row.required = YES;
    [section addFormRow:row];
    
    // Number
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kNumber rowType:XLFormRowDescriptorTypePhone title:@"Phone number:"];
    [row.cellConfigAtConfigure setObject:@"Required..." forKey:@"textField.placeholder"];
    [row.cellConfigAtConfigure setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    row.required = YES;
    [row addValidator:[XLFormRegexValidator formRegexValidatorWithMsg:@"Wrong number" regex:@"[0-9]{10,11}"]];
    [section addFormRow:row];
    
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@""];
    section.footerTitle = @"";
    [form addFormSection:section];
    
    // Button
    XLFormRowDescriptor * buttonRow = [XLFormRowDescriptor formRowDescriptorWithTag:kButton rowType:XLFormRowDescriptorTypeButton title:@"Register with phone"];
    buttonRow.action.formSelector = @selector(didTouchButton:);
    [section addFormRow:buttonRow];
    
    
    section1 = [XLFormSectionDescriptor formSectionWithTitle:@"Register with email"];
    [form addFormSection:section1];
    
    // Email
    // Name
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kName rowType:XLFormRowDescriptorTypeText title:@"Name:"];
    row.required = YES;
    [section1 addFormRow:row];
    
    // Email
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kEmail rowType:XLFormRowDescriptorTypeText title:@"Email"];
    [row.cellConfigAtConfigure setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    row.required = YES;
    row.value = @"email";
    [row addValidator:[XLFormValidator emailValidator]];
    [section1 addFormRow:row];
    
    // Password
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kPassword rowType:XLFormRowDescriptorTypePassword title:@"Password"];
    [row.cellConfigAtConfigure setObject:@"Required..." forKey:@"textField.placeholder"];
    [row.cellConfigAtConfigure setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    row.required = YES;
    [row addValidator:[XLFormRegexValidator formRegexValidatorWithMsg:@"At least 6, max 32 characters" regex:@"^(?=.*\\d)(?=.*[A-Za-z]).{6,32}$"]];
    [section1 addFormRow:row];
    
    section1 = [XLFormSectionDescriptor formSectionWithTitle:@""];
    section1.footerTitle = @"";
    [form addFormSection:section1];
    
    // Register click
    XLFormRowDescriptor * registerEmailButotn = [XLFormRowDescriptor formRowDescriptorWithTag:kRegisterEmail rowType:XLFormRowDescriptorTypeButton title:@"Register with email"];
    registerEmailButotn.action.formSelector = @selector(registerWithEmailClick:);
    [section1 addFormRow:registerEmailButotn];
    
    
    self.form = form;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = @"User register";
    self.navigationController.navigationBarHidden = false;

    //set null title back button
    UIBarButtonItem *item = [[UIBarButtonItem alloc] init];
    item.title = @"";
    self.navigationItem.backBarButtonItem = item;
}

-(void)didTouchButton:(UIButton*) button
{
    NSLog(@"Register click");
    BOOL validate =  [self validateForm];
    if(validate) {
        [self showVerifyView];
    }
}

-(void) registerWithEmailClick:(UIButton *) button
{
    BOOL validate = [self validateEmailAndPassword];
    if (validate) {
        NSLog(@"start register with email");
        [self createUserWithEmail];
        
    }
}


-(void) createUserWithEmail{
    
    NSDictionary *formValue = self.formValues;
    NSLog(@"form value is %@",formValue);
    NSString *email = [formValue objectForKey:kEmail];
    NSString *password = [formValue objectForKey:kPassword];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[formValue objectForKey:kName] forKey:UserName];
    [userDefault setObject:@"" forKey:UserPhone];

    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
                                 // ...
                                 if (error) {
                                     NSLog(@"register with email error");
                                 }else{
                                     NSLog(@"register success with user %@",user);
                                     [[ObserveMyself shareInstance] startObserve];
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

-(void) showVerifyView
{

    NSDictionary *formValue = self.formValues;
    NSLog(@"form value is %@",formValue);
    NSString *phoneNumber = [formValue objectForKey:kNumber];
    phoneNumber = [NSString stringWithFormat:@"+84%@",phoneNumber];
    
    NSLog(@"actually phone number is %@",phoneNumber);
    
    [[FIRPhoneAuthProvider provider] verifyPhoneNumber:phoneNumber
                                            UIDelegate:nil
                                            completion:^(NSString * _Nullable verificationID, NSError * _Nullable error) {
                                                if (error) {
//                                                    [self showMessagePrompt:error.localizedDescription];
                                                    NSLog(@"error is %@",error.localizedDescription);
                                                    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error happen" message:@"Your number is not right, you can try another number" preferredStyle:UIAlertControllerStyleAlert];
                                                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                                                    [alertView addAction:cancel];
                                                    [self presentViewController:alertView animated:YES completion:nil];
                                                    
                                                    return;
                                                }
                                                else
                                                {  // Sign in using the verificationID and the code sent to the user
                                                    // ...
                                                    NSLog(@"vefiry phone success ======== with verification id is %@",verificationID);
                                                    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                                                    [userDefault setObject:verificationID forKey:AuthVerificationID];
                                                    // save user name to update later, this logic seems still need to improve
                                                    [userDefault setObject:[formValue objectForKey:kName] forKey:UserName];
                                                    [userDefault setObject:[formValue objectForKey:kNumber] forKey:UserPhone];
                                                    
                                                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                                    VerifyCode *verifyCode = [storyboard  instantiateViewControllerWithIdentifier:@"VerifyCode"];
                                                    verifyCode.userRegistedType = self.userRegistedType;
                                                    [self.navigationController pushViewController:verifyCode animated:true] ;
                                            }
                                              
                                            }];
   
    
}





#pragma mark - actions
-(BOOL)validateForm
{
     __block BOOL validate = true;
    
    NSArray * array = [self formValidationErrors];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        XLFormValidationStatus * validationStatus = [[obj userInfo] objectForKey:XLValidationStatusErrorKey];
        if ([validationStatus.rowDescriptor.tag isEqualToString:kNumber]){
            validate = false;
            UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[self.form indexPathOfFormRow:validationStatus.rowDescriptor]];
            [self animateCell:cell];
        }
        
    }];
    
    return validate;
}

-(BOOL) validateEmailAndPassword
{
    __block BOOL validate = true;
    
    NSArray * array = [self formValidationErrors];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        XLFormValidationStatus * validationStatus = [[obj userInfo] objectForKey:XLValidationStatusErrorKey];
      if ([validationStatus.rowDescriptor.tag isEqualToString:kEmail]){
           validate = false;
            UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[self.form indexPathOfFormRow:validationStatus.rowDescriptor]];
            [self animateCell:cell];
        }
        else if ([validationStatus.rowDescriptor.tag isEqualToString:kPassword]){
            validate = false;
            UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:[self.form indexPathOfFormRow:validationStatus.rowDescriptor]];
            [self animateCell:cell];
        }
    }];
    
    return validate;
}



#pragma mark - Helper

-(void)animateCell:(UITableViewCell *)cell
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"position.x";
    animation.values =  @[ @0, @20, @-20, @10, @0];
    animation.keyTimes = @[@0, @(1 / 6.0), @(3 / 6.0), @(5 / 6.0), @1];
    animation.duration = 0.3;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.additive = YES;
    
    [cell.layer addAnimation:animation forKey:@"shake"];
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
