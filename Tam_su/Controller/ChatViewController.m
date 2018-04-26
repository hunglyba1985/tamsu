//
//  ChatViewController.m
//  Tam_su
//
//  Created by MacOS on 3/12/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "ChatViewController.h"
#import "JSQMessagesAvatarImageFactory.h"

@import Photos;

NSString *const imageURLNotSetKey = @"NOTSET";

@interface ChatViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL receiverStatus;
    BOOL writeChanelOnReceiver;
    NSString *channelId;
    BOOL observeConversationDone;
    BOOL isTyping;
    NSDictionary *chaterIcon;
}
@property (nonatomic,strong) NSMutableArray *messages;
@property (nonatomic,strong) NSMutableArray *tempMessages;
@property (nonatomic,strong) NSMutableDictionary *photoMessageMap;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRStorageReference *storageRef;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /**
     *  Load up our data for chat view
     */
    _messages = [NSMutableArray new];
    _tempMessages = [NSMutableArray new];
    _photoMessageMap = [NSMutableDictionary new];
    
    /**
     *  Set up message accessory button delegate and configuration
     */
//    self.collectionView.accessoryDelegate = self;
    
    self.ref = [[FIRDatabase database] reference];
    
    // [START configurestorage]
    self.storageRef = [[FIRStorage storage] reference];
    // [END configurestorage]

    if ([self.receiver[UserActive] isEqualToString:Active]) {
        receiverStatus = YES;
    }else{
        receiverStatus = NO;
    }
    [self observeStatusOfReceiver];
    [self startObserveConversation];
    [self setAvartaForChater];
    
}



-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationOnApp:) name:NotificationHaveMessageOnApp object:nil];

}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = YES;
    
}

-(void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    // TODO: delete all messages on this channel when user leave this view
//    [self deleteAllMessageOnChannle];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
#pragma mark Set Avatar For Chater
-(void) setAvartaForChater{
    
    UIImage* circuleSenderImage = [JSQMessagesAvatarImageFactory  circularAvatarImage:[UIImage imageNamed:@"menIcon"] withDiameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    UIImage* circuleReceiverImage = [JSQMessagesAvatarImageFactory  circularAvatarImage:[UIImage imageNamed:@"womenIcon"] withDiameter:kJSQMessagesCollectionViewAvatarSizeDefault];
    
    JSQMessagesAvatarImage *senderImage = [JSQMessagesAvatarImage avatarWithImage:circuleSenderImage];
    JSQMessagesAvatarImage *receiverImage = [JSQMessagesAvatarImage avatarWithImage:circuleReceiverImage];
    
    chaterIcon = @{
                   [FIRAuth auth].currentUser.uid:senderImage,
                   self.receiver[UserId]:receiverImage,
                   };
    
    
}

-(void) showNotificationOnApp:(NSNotification *) notification
{
    NSDictionary *notificationInfo = notification.userInfo;
    NSLog(@"myself id is %@",[FIRAuth auth].currentUser.uid);
    if (![notificationInfo[SenderId] isEqualToString:[FIRAuth auth].currentUser.uid]) {
        NSLog(@"sender is not myself");
        if (![notificationInfo[SenderId] isEqualToString:self.receiver[UserId]] ) {
            NSLog(@"sender is not receiver");
            NSString *alertStr = [NSString stringWithFormat:@"%@: %@",notificationInfo[SenderName],notificationInfo[TexMessage]];
            [JDStatusBarNotification showWithStatus:alertStr dismissAfter:2 styleName:JDStatusBarStyleSuccess];
        }
    }
   
   
}


-(void) deleteAllMessageOnChannle{
    if (channelId) {
        NSLog(@"delete All Message On Channle ");
        [[[_ref child:Channel] child:channelId] removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (error) {
                NSLog(@"remove all message error");
            }else{
                NSLog(@"remove all messages success");
            }
        }];
        
    }
}
// TODO: OBSERVE USER TYPING TO SHOW FOR RECEIVER
-(void) observeUserTypingToShowReceiver{
    if (channelId) {
        [[[[[[self.ref child:Channel] child:channelId] child:TypingIndicate] queryOrderedByValue]
          queryEqualToValue:@YES]
         observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
             NSLog(@"observe User Typing To Show Receiver");
             // You're the only typing, don't show the indicator
             if (snapshot.childrenCount == 1 && isTyping) {
                 return;
             }
             
             // Are there other typing?
             self.showTypingIndicator = snapshot.childrenCount > 0;
             [self scrollToBottomAnimated:YES];
             
         }];
    }
    
}


// TODO: Observe Status of Receiver
-(void) observeStatusOfReceiver{
    [[[_ref child:UserCollection] child:self.receiver[UserId]] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        // Get user value
        self.receiver = snapshot.value;
//        NSLog(@"receiver info %@",self.receiver);
        if ([self.receiver[UserActive] isEqualToString:Active]) {
            receiverStatus = YES;
        }else{
            receiverStatus = NO;
        }
        // ...
    } withCancelBlock:^(NSError * _Nonnull error) {
        NSLog(@"%@", error.localizedDescription);
    }];
}

// TODO: GET MESSAGES FROM FIREBASE
-(void) startObserveConversation{
    
    NSArray *listChannels = [ObserveMyself shareInstance].info[UserChannel];
    NSLog(@"list channle of myself is %@",listChannels);
//    NSLog(@"receive information %@",self.receiver);
    for (NSString *conversationId in listChannels) {
        if ([conversationId containsString:self.receiver[UserId]]) {
            NSLog(@"we get conversation id is %@",conversationId);
            channelId = conversationId;
        }
    }
    if (channelId) {
        observeConversationDone = YES;
        [[[[_ref child:Channel] child:channelId] child:MessageCollection] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get newsest message here
            NSDictionary *newestMessage = snapshot.value;
//            NSLog(@"newest message is %@",newestMessage);
            if (newestMessage[PhotoURL] == nil) {
                JSQMessage *message = [JSQMessage    messageWithSenderId:newestMessage[SenderId]
                                                             displayName:newestMessage[SenderName]
                                                                    text:newestMessage[TexMessage]];
                [self.messages addObject:message];
                [self finishReceivingMessageAnimated:YES];
            }else{
                BOOL maskAsOutgoing = [newestMessage[SenderId] isEqualToString:self.senderId];
                JSQPhotoMediaItem *mediaItem =  [[JSQPhotoMediaItem alloc]  initWithMaskAsOutgoing:maskAsOutgoing];
                [self addPhotoMessageWithSenderId:newestMessage[SenderId] andKey:newestMessage[MessageId] andMediaItem:mediaItem];
                
                if (![newestMessage[PhotoURL] isEqualToString:imageURLNotSetKey]) {
                    [self fetchImageDataAtUrl:newestMessage[PhotoURL] forMediaItem:mediaItem clearsPhotoMessageMapOnSuccessForKey:newestMessage[MessageId]];
                }
            }
            [self deleteMessagesWhenItLargerThanFive];
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
        
        
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        [[[[_ref child:Channel] child:channelId] child:MessageCollection] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            // Get newsest message here
            NSDictionary *newestMessage = snapshot.value;
            //            NSLog(@"newest message is %@",newestMessage);
            if (newestMessage[PhotoURL]) {
                JSQPhotoMediaItem *mediaItem = self.photoMessageMap[newestMessage[MessageId]];
                [self fetchImageDataAtUrl:newestMessage[PhotoURL] forMediaItem:mediaItem clearsPhotoMessageMapOnSuccessForKey:newestMessage[MessageId]];
                
            }
            
        } withCancelBlock:^(NSError * _Nonnull error) {
            NSLog(@"%@", error.localizedDescription);
        }];
        
        
        [self observeUserTypingToShowReceiver];
    }else{
        NSLog(@"don't get channel id from myself because we can't get it");
    }
  
}

-(void) deleteMessagesWhenItLargerThanFive{
    if (self.messages.count > 7) {
        NSLog(@"start delete message when it larger than 5");
        for (int i = 0; i < (self.messages.count - 5); i++) {
            [self.messages removeObjectAtIndex:i];
        }
        [self finishSendingMessageAnimated:YES];
    }
}


#pragma mark - JSQMessagesViewController method overrides
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    NSLog(@"did press send button ------");
    
//    NSLog(@"we get tex message here: %@ from sender id: %@ and sender display name is: %@",text,senderId,senderDisplayName);
    // TODO: Start create new channel and add notification for receiver know they have conversation
   
    [self writeChannelOnReceiver];
    [self checkReceiverActiveOrNotToSendNotification];
   
    NSDictionary *messageItem = @{
                                  SenderId:[FIRAuth auth].currentUser.uid,
                                  SenderName:[ObserveMyself shareInstance].info[UserName],
                                  TexMessage:text,
                                  MessageId:[[NSUUID UUID] UUIDString]
                                  };

    [self sendMessageToChannles:messageItem];
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessageAnimated:YES];
    isTyping = NO;
    [self sendUserTypingStatusToFirebase:isTyping];
}

// TODO: SEND PHOTO MESSAGE
// Idiea for send photo message is we send photo message with FAKE URL and update the message once the photo has been saved.
-(NSString *) sendPhotoMessage{
    [self writeChannelOnReceiver];
    [self checkReceiverActiveOrNotToSendNotification];
    
    NSDictionary *messageItem = @{
                                  SenderId:[FIRAuth auth].currentUser.uid,
                                  SenderName:[ObserveMyself shareInstance].info[UserName],
                                  PhotoURL:imageURLNotSetKey,
                                  MessageId:[[NSUUID UUID] UUIDString]
                                  };
    
    [self sendMessageToChannles:messageItem];
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [self finishSendingMessageAnimated:YES];
    
    return messageItem[MessageId];
}

-(void) updateRealImageUrl:(NSString*) urlStr forPhotoMessageWithKey:(NSString*) key {
    
    [[[[[_ref child:Channel] child:channelId] child:MessageCollection] child:key]
     updateChildValues:@{PhotoURL:urlStr} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error) {
             NSLog(@"error with adding document %@",error);
         }else{
             NSLog(@"update url string for photo message");
         }
     }];
}

-(void) addPhotoMessageWithSenderId:(NSString *) senderId andKey:(NSString*) key andMediaItem:(JSQPhotoMediaItem *) mediaItem{
    JSQMessage *message = [JSQMessage messageWithSenderId:senderId displayName:@"" media:mediaItem];
    [self.messages addObject:message];
    
    if (mediaItem.image == nil) {
        [self.photoMessageMap setObject:mediaItem forKey:key];
    }
    
    [self.collectionView reloadData];
    
}

-(void) fetchImageDataAtUrl:(NSString *) photoUrl forMediaItem:(JSQPhotoMediaItem *) mediaItem clearsPhotoMessageMapOnSuccessForKey:(NSString*) key{
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:[NSURL URLWithString:photoUrl] options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL)
    {
            mediaItem.image = image;
            [self.collectionView reloadData];
            [self.photoMessageMap removeObjectForKey:key];
    }];
    
    
    
//    FIRStorage *storage = [FIRStorage storage];
//    FIRStorageReference *storageRef = [storage reference];
//    NSString *imagePath = photoUrl;
//    FIRStorageReference *userImage = [storageRef child:imagePath];
//
//    // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
//    [userImage dataWithMaxSize:1 * 1024 * 1024 completion:^(NSData *data, NSError *error){
//        if (error != nil) {
//            // Uh-oh, an error occurred!
//            NSLog(@"error when download image");
//        } else {
//            // Data for "images/island.jpg" is returned
//            NSLog(@"success get image from firebase");
//            UIImage *image = [UIImage imageWithData:data];
//            mediaItem.image = image;
//
//            [self.collectionView reloadData];
//
//            [self.photoMessageMap removeObjectForKey:key];
//        }
//    }];
}



// TODO: Send message to channel firebase
-(void) sendMessageToChannles:(NSDictionary *) messageItem
{
    if (channelId) {
        [[[[[_ref child:Channel] child:channelId] child:MessageCollection] child:messageItem[MessageId]]
         setValue:messageItem withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"send message to channel success");
                 if (!observeConversationDone) {
                     observeConversationDone = YES;
                     [self startObserveConversation];
                 }
             }
         }];
    }else{
        channelId = [NSString stringWithFormat:@"%@+%@",[FIRAuth auth].currentUser.uid,self.receiver[UserId]];
        [[[[[_ref child:Channel] child:channelId] child:MessageCollection] child:messageItem[MessageId]]
         setValue:messageItem withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"send message to channel success");
                 if (!observeConversationDone) {
                     observeConversationDone = YES;
                     [self startObserveConversation];
                 }
             }
         }];
    }
   
}


-(void) writeChannelOnReceiver{
    if (!writeChanelOnReceiver) {
        NSLog(@"write channel of receiver ------------------------------------");
        writeChanelOnReceiver = YES;
        NSArray *channels = self.receiver[UserChannel];
        NSLog(@"receiver have channels ----------------- %@",channels);
        BOOL receiverHaveChannel = NO;
        for (NSString *channelId in channels) {
            if ([channelId containsString:[FIRAuth auth].currentUser.uid]) {
                receiverHaveChannel = YES;
            }
        }
        if (!receiverHaveChannel) {
            NSLog(@"receiver don't have this channel -----------");
            // TODO: Continue check if myself have channelid and get it to add to receiver
            // if myself don't have channelId create one to add

            NSArray *myselfChannels = [ObserveMyself shareInstance].info[UserChannel];
            NSString *combineId;
            for (NSString *channleId in myselfChannels) {
                if ([channleId containsString:self.receiver[UserId]]) {
                    combineId = channleId;
                }
            }
            if (!combineId) {
                combineId = [NSString stringWithFormat:@"%@+%@",[FIRAuth auth].currentUser.uid,self.receiver[UserId]];
            }
            
            NSLog(@"finally channel id will be like this --------- %@",combineId);
            
            NSMutableArray *receiverOldChannels = [[NSMutableArray alloc] initWithArray:self.receiver[UserChannel]];
            [receiverOldChannels addObject:combineId];
            
            NSDictionary *receiverConversation = @{
                                                   UserChannel:receiverOldChannels
                                                   };
            [[[_ref child:UserCollection] child:self.receiver[UserId]]
             updateChildValues:receiverConversation withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                 if (error) {
                     NSLog(@"error with adding document %@",error);
                 }else{
                     NSLog(@"add user channel id on both receiver and sender");
                 }
             }];
        }
    }
}

// TODO: Check receiver is active or not to SEND NOTIFICATION
-(void) checkReceiverActiveOrNotToSendNotification{
    if (!receiverStatus) {
        NSLog(@"receiver inactive ------");
        NSDictionary *notification = @{ReceiverId:self.receiver[UserId],
                                       SenderId:[FIRAuth auth].currentUser.uid,
                                       SenderName:[ObserveMyself shareInstance].info[UserName]
                                       };
        [[[_ref child:Notification] childByAutoId]
         updateChildValues:notification withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
             if (error) {
                 NSLog(@"error with adding document %@",error);
             }else{
                 NSLog(@"send notification for receiver ");
             }
             
         }];
    }else{
        NSLog(@"receiver active");
    }
}

#pragma mark Handle Send Image or Video
- (void)didPressAccessoryButton:(UIButton *)sender
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    NSLog(@"did press accessory button");
    [self openSelectionChoiceCameraOrLibrary];
}

-(void) openSelectionChoiceCameraOrLibrary{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
        // Cancel button tappped.
        [self dismissViewControllerAnimated:YES completion:^{
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:^{
        }];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:picker animated:YES completion:NULL];
        }
        else{
            NSLog(@"can open camera");
        }
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // OK button tapped.
        [self dismissViewControllerAnimated:YES completion:^{
        }];
        
        NSLog(@"select library ");
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:NULL];
    }]];
    
    // Present action sheet.
    [self presentViewController:actionSheet animated:YES completion:nil];
}

-(void) openCameraOrLibraryToGetImage{
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
//    _urlTextView.text = @"Beginning Upload";
    NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
    // if it's a photo from the library, not an image from the camera
    if (referenceUrl) {
        NSLog(@"get image from library -------");
        PHFetchResult* assets = [PHAsset fetchAssetsWithALAssetURLs:@[referenceUrl] options:nil];
        PHAsset *asset = assets.firstObject;
        [asset requestContentEditingInputWithOptions:nil
                                   completionHandler:^(PHContentEditingInput *contentEditingInput,
                                                       NSDictionary *info) {
                                       NSLog(@"ge image from library --------");
                                       UIImage *image = contentEditingInput.displaySizeImage;
                                       NSString * key =  [self sendPhotoMessage];
                                       NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
                                       NSString *imagePath =
                                       [NSString stringWithFormat:@"%@/%lld.jpg",
                                        [FIRAuth auth].currentUser.uid,
                                        (long long)([NSDate date].timeIntervalSince1970 * 1000.0)];
                                       FIRStorageMetadata *metadata = [FIRStorageMetadata new];
                                       metadata.contentType = @"image/jpeg";
                                       [[_storageRef child:imagePath] putData:imageData metadata:metadata
                                                                   completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                                                                       if (error) {
                                                                           NSLog(@"Error uploading: %@", error);
                                                                           //                                            _urlTextView.text = @"Upload Failed";
                                                                           return;
                                                                       }
                                                                       [self updateRealImageUrl:[metadata.downloadURL absoluteString] forPhotoMessageWithKey:key];
                                                                       
                                                                   }];
                                   }];
        
    } else {
        NSLog(@"ge image from camera --------");
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSString * key =  [self sendPhotoMessage];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *imagePath =
        [NSString stringWithFormat:@"%@/%lld.jpg",
         [FIRAuth auth].currentUser.uid,
         (long long)([NSDate date].timeIntervalSince1970 * 1000.0)];
        FIRStorageMetadata *metadata = [FIRStorageMetadata new];
        metadata.contentType = @"image/jpeg";
        [[_storageRef child:imagePath] putData:imageData metadata:metadata
                                    completion:^(FIRStorageMetadata * _Nullable metadata, NSError * _Nullable error) {
                                        if (error) {
                                            NSLog(@"Error uploading: %@", error);
//                                            _urlTextView.text = @"Upload Failed";
                                            return;
                                        }
                                        [self updateRealImageUrl:[metadata.downloadURL absoluteString] forPhotoMessageWithKey:key];

                                    }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark TextView Delegate To Check User typing
-(void) textViewDidChange:(UITextView *)textView{
    [super textViewDidChange:textView];
    
//    NSLog(@"if text view did change %@",textView.text);
    isTyping = ![textView.text isEqualToString:@""];
    [self sendUserTypingStatusToFirebase:isTyping];
}

-(void) sendUserTypingStatusToFirebase:(BOOL) status{
    
    if (channelId) {
        FIRDatabaseReference *userIsTypingRef =[[[[_ref child:Channel] child:channelId] child:TypingIndicate] child:[FIRAuth auth].currentUser.uid];
        [userIsTypingRef setValue:[NSNumber numberWithBool:status] withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
            if (error) {
                NSLog(@"send user typing status to firebase error");
            }else{
                NSLog(@"send user typing status to firebase success");
            }
        }];
        
    }
   
}

#pragma mark - JSQMessages CollectionView DataSource

- (NSString *)senderId {
    return [FIRAuth auth].currentUser.uid;
}

- (NSString *)senderDisplayName {
    if ([ObserveMyself shareInstance].info[UserName]) {
        return [ObserveMyself shareInstance].info[UserName];
    }else{
        return @"";
    }

}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.messages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];

    if ([message.senderId isEqualToString:self.senderId]) {
        return [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    }
    
    return [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
//    NSLog(@"message sender name is -------------- %@",message.senderDisplayName);
//    NSLog(@"message sender id is ---------------%@",message.senderId);
    return [chaterIcon objectForKey:message.senderId];                 // [self.demoData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
//    cell.accessoryButton.hidden = ![self shouldShowAccessoryButtonForMessage:msg];
    
    return cell;
}

//- (BOOL)shouldShowAccessoryButtonForMessage:(id<JSQMessageData>)message
//{
//    return ([message isMediaMessage] && [NSUserDefaults accessoryButtonForMediaMessages]);
//}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
//    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
//    NSDictionary *temMsg = [self.tempMessages objectAtIndex:indexPath.item];
//
//    NSLog(@"didEndDisplayingCell %@",msg.text);
//    NSLog(@"didEndDisplayingCell temp data %@",temMsg[TexMessage]);
//    [self deleteMessageReaded:msg atIndex:indexPath];
    
}

// TODO: Delete readed message
-(void) deleteMessageReaded:(JSQMessage *) message atIndex:(NSIndexPath *) indexPath{
    NSDictionary *tempMsg = [self.tempMessages objectAtIndex:indexPath.item];
    
    [[[[_ref child:Channel] child:channelId] child:tempMsg[MessageId]]
     removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        if (error) {
            NSLog(@"remove all message error");
        }else{
            NSLog(@"delete Message Readed success");
            if (self.messages.count >= indexPath.item) {
                [self.messages removeObjectAtIndex:indexPath.item];
                [self.tempMessages removeObjectAtIndex:indexPath.item];
            }
            [self finishReceivingMessageAnimated:YES];
        }
    }];
}



- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
//    JSQMessage *msg = [self.messages objectAtIndex:indexPath.item];
    
//    NSLog(@"willDisplayCell %@",msg.text);
}


#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}


#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];
    if ([message isMediaMessage]) {
        JSQPhotoMediaItem *messageImage = (JSQPhotoMediaItem *) message.media;
        
    }
    
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
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
