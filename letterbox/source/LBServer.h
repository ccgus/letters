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
    
    FMDatabase          *cacheDB;
    
    NSMutableArray      *inactiveIMAPConnections;
    NSMutableArray      *activeIMAPConnections;
}

@property (retain) LBAccount *account;
@property (retain) NSURL *baseCacheURL;
@property (retain) NSURL *accountCacheURL;

    // this is temp, until we get a real cache.
@property (readonly, retain) NSMutableDictionary *foldersCache;
@property (retain) NSArray *foldersList;


- (id)initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL;

- (void)connectUsingBlock:(void (^)(BOOL, NSError *))block;

- (void)checkForMail;

- (NSArray*)messageListForPath:(NSString*)folderPath;

- (void)moveMessages:(NSArray*)messageList inFolder:(NSString*)currentFolder toFolder:(NSString*)folder finshedBlock:(void (^)(BOOL, NSError *))block;

@end
