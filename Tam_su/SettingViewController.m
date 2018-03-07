//
//  SettingViewController.m
//  Tam_su
//
//  Created by MacOS on 3/7/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "SettingViewController.h"
#import "UserRegister.h"


NSString *const kUserLogout = @"userLogout";

@interface SettingViewController ()

@end

@implementation SettingViewController
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
    //    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptor];
    
    section = [XLFormSectionDescriptor formSectionWithTitle:@""];
    section.footerTitle = @"";
    [form addFormSection:section];
    
    
    //    // Image
    //    row = [XLFormRowDescriptor formRowDescriptorWithTag:kImage rowType:XLFormRowDescriptorTypeImage title:@"Image"];
    //    row.value = [UIImage imageNamed:@"default_avatar"];
    //    [section addFormRow:row];
    
    // Name
    //    row = [XLFormRowDescriptor formRowDescriptorWithTag:kBrandName rowType:XLFormRowDescriptorTypeText title:@"Brand Name:"];
    //    row.required = YES;
    //    [section addFormRow:row];
    //
    //    // Number
    //    row = [XLFormRowDescriptor formRowDescriptorWithTag:kCarNumber rowType:XLFormRowDescriptorTypePhone title:@"Car number:"];
    //    [row.cellConfigAtConfigure setObject:@"Required..." forKey:@"textField.placeholder"];
    //    [row.cellConfigAtConfigure setObject:@(NSTextAlignmentRight) forKey:@"textField.textAlignment"];
    //    row.required = YES;
    //    [row addValidator:[XLFormRegexValidator formRegexValidatorWithMsg:@"Wrong number" regex:@"[0-9]{10}"]];
    //    [section addFormRow:row];
    //
    //
    section = [XLFormSectionDescriptor formSectionWithTitle:@""];
    section.footerTitle = @"";
    [form addFormSection:section];
    //
    // Button
    XLFormRowDescriptor * yourTrip = [XLFormRowDescriptor formRowDescriptorWithTag:kUserLogout rowType:XLFormRowDescriptorTypeButton title:@"Logout"];
    [yourTrip.cellConfig setObject:@(NSTextAlignmentNatural) forKey:@"textLabel.textAlignment"];
    [yourTrip.cellConfig setObject:[UIColor redColor] forKey:@"textLabel.textColor"];
    yourTrip.action.formSelector = @selector(userLogout);
    [section addFormRow:yourTrip];
    
    
    
    self.form = form;
    
}


-(void) userLogout
{
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    else
    {
        NSLog(@"sign out success");
        UserRegister *welcomeView = [self.storyboard instantiateViewControllerWithIdentifier:@"UserRegister"];
        [self.navigationController pushViewController:welcomeView animated:YES];
        
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
