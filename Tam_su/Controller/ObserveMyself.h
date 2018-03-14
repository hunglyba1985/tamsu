//
//  ObserveMyself.h
//  Tam_su
//
//  Created by MacOS on 3/14/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ObserveMyself : NSObject
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) NSDictionary *info;
+(ObserveMyself *) shareInstance;
-(void) startObserve;



@end
