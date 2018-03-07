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


NSString *const kName = @"name";
NSString *const kNumber = @"number";
NSString *const kButton = @"button";

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
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptor];
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@"Please set information below to register"];
    section.footerTitle = @"We can add more text here to infor user";
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
    XLFormRowDescriptor * buttonRow = [XLFormRowDescriptor formRowDescriptorWithTag:kButton rowType:XLFormRowDescriptorTypeButton title:@"Register"];
    buttonRow.action.formSelector = @selector(didTouchButton:);
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
                                                    [userDefault setObject:[formValue objectForKey:kName] forKey:UserNameUpdate];
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
