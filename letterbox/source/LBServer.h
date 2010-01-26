//
//  LBServer.h
//  LetterBox
//
//  Created by August Mueller on 1/20/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libetpan/libetpan.h>

extern NSString *LBServerFolderUpdatedNotification;
extern NSString *LBServerSubjectsUpdatedNotification;
extern NSString *LBServerBodiesUpdatedNotification;

@class LBAccount;
@class LBFolder;
@class FMDatabase;


@interface LBServer : NSObject {
    LBAccount *_account;
    
    NSURL               *_baseCacheURL;
    NSURL               *_accountCacheURL;
    FMDatabase          *_cacheDB;
    
    NSMutableArray      *_inactiveIMAPConnections;
    NSMutableArray      *_activeIMAPConnections;
    
    // this is temp, until we get a real cache.
    NSMutableDictionary *_foldersCache;
    NSArray             *_foldersList;
}

@property (retain) LBAccount *account;
@property (retain) NSURL *baseCacheURL;
@property (retain) NSURL *accountCacheURL;
@property (readonly, retain) NSMutableDictionary *foldersCache;
@property (retain) NSArray *foldersList;


- (id) initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL;

- (void) connectUsingBlock:(void (^)(BOOL, NSError *))block;

- (void) checkForMail;

- (NSArray*) messageListForPath:(NSString*)folderPath;

@end
