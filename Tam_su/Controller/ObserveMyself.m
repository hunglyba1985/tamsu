//
//  ObserveMyself.m
//  Tam_su
//
//  Created by MacOS on 3/14/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "ObserveMyself.h"

static ObserveMyself *_shareClient;


@implementation ObserveMyself


+(ObserveMyself *) shareInstance
{
    if(!_shareClient) {
        _shareClient = [[ObserveMyself alloc] init];
    }
    return _shareClient;
}

- (id) init {
    self = [super init];
    if (self) {
        self.ref = [[FIRDatabase database] reference];
    }
    
    return self;
}

-(void) startObserve
{
    [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get user value
       self.info = snapshot.value;
        NSLog(@"myself information is %@",self.info);
        NSArray *channels = self.info[UserChannel];
        NSLog(@"myself channels is %@",channels);
        for (NSString *channelId in channels) {
            [self observeConversationOnChannel:channelId];
        }
        
        // ...
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}
-(void) observeConversationOnChannel:(NSString*) channelId{
    NSLog(@"observeConversationOnChannel with id %@",channelId);
    [[[_ref child:Channel] child:channelId] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get newsest message here
        NSDictionary *newestMessage = snapshot.value;
        NSLog(@"newest message is %@",newestMessage);
       
        // ...
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
    
}

@end













