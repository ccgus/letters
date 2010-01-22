//
//  LBServer.h
//  LetterBox
//
//  Created by August Mueller on 1/20/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libetpan/libetpan.h>


@class LBAccount;
@class LBFolder;
@class FMDatabase;

/*!
 @class LBServer
 LBServer is the base class with which you establish a connection to the 
 IMAP server. After establishing a connection with LBServer you can access 
 all of the folders (I use the term folder instead of mailbox) on the server.
 All methods throw an exception on failure.
 */


@interface LBServer : NSObject {
    LBAccount *_account;
    struct mailstorage  *_storage;
    BOOL                _connected;
    NSURL               *_baseCacheURL;
    NSURL               *_accountCacheURL;
    FMDatabase          *_cacheDB;
}

@property (retain) LBAccount *account;
@property (retain) NSURL *baseCacheURL;
@property (retain) NSURL *accountCacheURL;


// FIXME: documentation, steal from connect
- (id) initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL;

/*!
 @abstract   Retrieves the list of all the available folders from the server.
 @result     Returns a NSSet which contains NSStrings of the folders pathnames.
 */
- (NSArray *)allFolders;

/*!
 @abstract   Retrieves a list of only the subscribed folders from the server.
 @result     Returns a NSSet which contains NSStrings of the folders pathnames.
 */
- (NSArray *)subscribedFolders;

/*!
 @abstract   If you have the path of a folder on the server use this method to retrieve just the one folder.
 @param      path A NSString specifying the path of the folder to retrieve from the server.
 @result     Returns a LBFolder.
 */
- (LBFolder *)folderWithPath:(NSString *)path;

// FIXME: document
- (void) loadCache;

// FIXME: document
- (NSArray*) cachedFolders;
- (NSArray*) cachedMessagesForFolder:(NSString*)folder;

/*xxx!
 @abstract   This method initiates the connection to the server.
 @param      server The address of the server.
 @param      port The port to connect to.
 @param      connnectionType What kind of connection to use, it can be one of these three values:
 CONNELBION_TYPE_PLAIN, CONNELBION_TYPE_STARTTLS, CONNELBION_TYPE_TRY_STARTTLS, CONNELBION_TYPE_TLS
 @param      authType The authentication type, only IMAP_AUTH_TYPE_PLAIN is currently supported
 @param      login The username to connect with.
 @param      password The password to use to connect.
 */
- (void) connect;

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

// FIXME: don't make this public.
- (void) saveMessagesToCache:(NSSet*)messages forFolder:(NSString*)folderName; 

@end
