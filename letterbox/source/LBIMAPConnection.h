//
//  LBIMAPConnection.h
//  LetterBox
//
//  Created by August Mueller on 1/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libetpan/libetpan.h>

#import "LBActivity.h"

@class LBFolder;
@class LBAccount;

@interface LBIMAPConnection : NSObject <LBActivity> {
    struct mailstorage  *storage;
    BOOL                connected;
    
    NSString            *activityStatus;
}

@property (assign) BOOL shouldCancelActivity;

/*!
 @abstract   Retrieves the list of all the available folders from the server.
 @result     Returns a NSSet which contains NSStrings of the folders pathnames.
 */
- (NSArray *)allFolders;

/*!
 @abstract   Retrieves a list of only the subscribed folders from the server.
 @result     Returns an ordered NSArray which contains NSStrings of the folders pathnames.
 */
- (NSArray *) subscribedFolderNames:(NSError**)outErr;

/*!
 @abstract   If you have the path of a folder on the server use this method to retrieve just the one folder.
 @param      path A NSString specifying the path of the folder to retrieve from the server.
 @result     Returns a LBFolder.
 */
- (LBFolder *)folderWithPath:(NSString *)path;

- (BOOL) connectWithAccount:(LBAccount*)account error:(NSError**)outErr;

/*!
 @abstract   This method returns the current connection status.
 @result     Returns YES or NO as the status of the connection.
 */
- (BOOL)isConnected;

/*!
 @abstract   Terminates the connection. If you terminate this connection it will also affect the
 connectivity of LBFolders and LBMessages that rely on this account.
 */
- (void)disconnect;

/* Intended for advanced use only */
- (mailimap *)session;
- (struct mailstorage *)storageStruct;


- (void)setActivityStatusAndNotifiy:(NSString *)value;
@end
