//
//  Utility.h
//  Tam_su
//
//  Created by MacOS on 3/19/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject
+(Utility *) shareInstance;

-(void) sendImageToFirebaseStore:(UIImage *) image;


@end
