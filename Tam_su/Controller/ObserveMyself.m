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
        self.arrayObserveConversation = [NSMutableArray new];
    }
    
    return self;
}

-(void) startObserve
{
    [[[_ref child:UserCollection] child:[FIRAuth auth].currentUser.uid] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get user value
       self.info = snapshot.value;
        NSLog(@"myself information is %@",self.info);
        NSArray *newestChannels = self.info[UserChannel];
        NSLog(@"myself channels is %@",newestChannels);
        // TODO: START OBSERVE ALL CONVERSATION
        if (newestChannels.count > self.arrayObserveConversation.count) {
            NSMutableSet *big = [NSMutableSet setWithArray:newestChannels];
            NSMutableSet *little = [NSMutableSet setWithArray:self.arrayObserveConversation];
            [big minusSet:little];
            NSArray *result = [big allObjects];
            NSLog(@"different channels is %@",result);
            [self.arrayObserveConversation addObjectsFromArray:result];
            for (NSString *channleId in result) {
                [self observeConversationOnChannel:channleId];
            }
            
            
        }else{
            NSLog(@"don't have new channle then leave it");
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
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationHaveMessageOnApp object:nil userInfo:newestMessage];
        // ...
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
    
    
}

@end













