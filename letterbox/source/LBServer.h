//
//  LBServer.h
//  LetterBox
//
//  Created by August Mueller on 1/20/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *LBServerFolderUpdatedNotification;
extern NSString *LBServerSubjectsUpdatedNotification;
extern NSString *LBServerBodiesUpdatedNotification;
extern NSString *LBServerMessageDeletedNotification;

typedef void (^LBResponseBlock)(NSError *);

@class LBAccount;
@class LBIMAPFolder;
@class FMDatabase;
@class LBIMAPConnection;
@class LBMessage;

@interface LBServer : NSObject {
    
    FMDatabase          *cacheDB;
    
    NSMutableArray      *inactiveIMAPConnections;
    NSMutableArray      *activeIMAPConnections;
    
    NSString            *serverCapabilityResponse;
}

@property (retain) LBAccount *account;
@property (retain) NSURL *baseCacheURL;
@property (retain) NSURL *accountCacheURL;

    // this is temp, until we get a real cache.
@property (readonly, retain) NSMutableDictionary *foldersCache;
@property (retain) NSArray *foldersList;

@property (readonly, retain) NSString *serverCapabilityResponse;

@property (readonly) BOOL capabilityUIDPlus;

- (id)initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL;

- (void)connectUsingBlock:(void (^)(NSError *))block;

- (void)checkForMail;
- (void)updateMessagesInMailbox:(NSString*)mailbox withBlock:(LBResponseBlock)block;

- (NSArray*)messageListForPath:(NSString*)folderPath;

- (void)moveMessage:(LBMessage*)message toMailbox:(NSString*)destinationMailbox withBlock:(LBResponseBlock)block;

- (void)deleteMessage:(LBMessage*)message withBlock:(LBResponseBlock)block;
//- (void)deleteMessageWithUID:(NSString*)serverUID inMailbox:(NSString*)mailbox withBlock:(LBResponseBlock)block;
//- (void)deleteMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block;
- (void)expungeWithBlock:(LBResponseBlock)block;

- (void)findCapabilityWithBlock:(LBResponseBlock)block;

- (void)clearCache;

@end
