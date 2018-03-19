//
//  Utility.m
//  Tam_su
//
//  Created by MacOS on 3/19/18.
//  Copyright © 2018 MacOS. All rights reserved.
//

#import "Utility.h"

static Utility *_shareClient;

@implementation Utility

+(Utility *) shareInstance
{
    if(!_shareClient) {
        _shareClient = [[Utility alloc] init];
    }
    return _shareClient;
}

- (id) init {
    self = [super init];
    if (self) {
    }
    return self;
}

-(void) sendImageToFirebaseStore:(UIImage *) image
{
    NSLog(@"start send image to firebase");
    NSData *imageData = UIImageJPEGRepresentation(image,0.8);
    FIRUser *user = [FIRAuth auth].currentUser;
    FIRStorage *storage = [FIRStorage storage];
    FIRStorageReference *storageRef = [storage reference];
    NSString *imagePath = [NSString stringWithFormat:@"%@/images/%@.jpg",UserCollection,user.uid];
    FIRStorageReference *userImage = [storageRef child:imagePath];
    
    // Create the file metadata
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/jpeg";
    
    FIRStorageUploadTask *uploadTask = [userImage putData:imageData
                                                 metadata:metadata
                                               completion:^(FIRStorageMetadata *metadata,
                                                            NSError *error) {
                                                   if (error != nil) {
                                                       // Uh-oh, an error occurred!
//                                                       if ([self.userRegistedType isEqualToString:TypeUser]) {
//                                                           UIAlertController *alertView = [UIAlertController alertControllerWithTitle:@"Error happen" message:@"Can't upload your image" preferredStyle:UIAlertControllerStyleAlert];
//                                                           UIAlertAction *try = [UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                                                               [self sendImageToFirebaseStore:userProfileImage];
//                                                           }];
//                                                           UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                                                               [self uploadUserProfileToFirebaseWithImageUrl:@""];
//                                                           }];
//                                                           [alertView addAction:try];
//                                                           [alertView addAction:continueAction];
//                                                           [self presentViewController:alertView animated:YES completion:nil];
//                                                       }
                                                       
                                                       
                                                   } else {
                                                       // Metadata contains file metadata such as size, content-type, and download URL.
                                                       NSURL *downloadURL = metadata.downloadURL;
                                                       NSLog(@"down load url%@",downloadURL);
//                                                       userImageUrl = [downloadURL absoluteString];
//                                                       [self uploadUserProfileToFirebaseWithImageUrl:[downloadURL absoluteString]];
                                                   }
                                               }];
    
    //    // Listen for state changes, errors, and completion of the upload.
    //    [uploadTask observeStatus:FIRStorageTaskStatusResume handler:^(FIRStorageTaskSnapshot *snapshot) {
    //        // Upload resumed, also fires when the upload starts
    //    }];
    //
    //    [uploadTask observeStatus:FIRStorageTaskStatusPause handler:^(FIRStorageTaskSnapshot *snapshot) {
    //        // Upload paused
    //    }];
    //
    //    [uploadTask observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot) {
    //        // Upload reported progress
    //        double percentComplete = 100.0 * (snapshot.progress.completedUnitCount) / (snapshot.progress.totalUnitCount);
    //        NSLog(@"Upload completed progress %f",percentComplete);
    //    }];
    //
    [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload completed successfully
        NSLog(@"Upload completed successfully");
    }];
    //
    // Errors only occur in the "Failure" case
    [uploadTask observeStatus:FIRStorageTaskStatusFailure handler:^(FIRStorageTaskSnapshot *snapshot) {
        if (snapshot.error != nil) {
            NSLog(@"Upload failure");
            switch (snapshot.error.code) {
                case FIRStorageErrorCodeObjectNotFound:
                    // File doesn't exist
                    break;
                    
                case FIRStorageErrorCodeUnauthorized:
                    // User doesn't have permission to access file
                    break;
                    
                case FIRStorageErrorCodeCancelled:
                    // User canceled the upload
                    break;
                    
                    /* ... */
                    
                case FIRStorageErrorCodeUnknown:
                    // Unknown error occurred, inspect the server response
                    break;
            }
        }
    }];
    
    
}




@end
