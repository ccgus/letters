//
//  LBServer.m
//  LetterBox
//
//  Created by August Mueller on 1/20/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBServer.h"
#import "LBAccount.h"
#import "LetterBoxTypes.h"
#import "LBIMAPFolder.h"
#import "LBAddress.h"
#import "LBIMAPMessage.h"
#import "FMDatabase.h"
#import "LBIMAPConnection.h"
#import "LBMessage.h"
#import "LetterBoxUtilities.h"

NSString *LBServerFolderUpdatedNotification = @"LBServerFolderUpdatedNotification";
NSString *LBServerSubjectsUpdatedNotification = @"LBServerSubjectsUpdatedNotification";
NSString *LBServerBodiesUpdatedNotification = @"LBServerBodiesUpdatedNotification";

// these are defined in LBActivity.h, but they need to go somewhere and I'm not making a .m just for them.
NSString *LBActivityStartedNotification = @"LBActivityStartedNotification";
NSString *LBActivityUpdatedNotification = @"LBActivityUpdatedNotification";
NSString *LBActivityEndedNotification   = @"LBActivityEndedNotification";

@interface LBServer ()
- (void)loadCache;
- (NSArray*)cachedMessagesForFolder:(NSString *)folder;
- (void)saveMessageToCache:(NSData*)messageData forMailbox:(NSString*)mailboxName;
- (void)checkForMailInMailboxList:(NSMutableArray*)mailboxList;
- (void)saveFoldersToCache:(NSArray*)messages;
@end


@implementation LBServer
@synthesize account;
@synthesize baseCacheURL;
@synthesize accountCacheURL;
@synthesize foldersCache;
@synthesize foldersList;

- (id)initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL {
    
	self = [super init];
	if (self != nil) {
		self.account        = anAccount;
        self.baseCacheURL   = cacheFileURL;
        
        inactiveIMAPConnections = [[NSMutableArray array] retain];
        activeIMAPConnections   = [[NSMutableArray array] retain];
        foldersCache = [[NSMutableDictionary dictionary] retain];
        foldersList  = [[NSArray array] retain];
        
        [self loadCache];
	}
    
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [account release];
    [baseCacheURL release];
    [accountCacheURL release];
    [cacheDB release];
    
    [inactiveIMAPConnections release];
    [activeIMAPConnections release];
    
    [super dealloc];
}

- (LBIMAPConnection*)checkoutIMAPConnection {
    
    // FIXME: this method isn't thread safe
    if (![[NSThread currentThread] isMainThread]) {
        NSLog(@"UH OH THIS IS BAD CHECKING OUT ON A NON MAIN THREAD NOOO.");
    }
    
    
    // FIXME: need to set an upper limit on these guys.
    
    LBIMAPConnection *conn = [inactiveIMAPConnections lastObject];
    
    if (!conn) {
        // FIXME: what about a second connection that hasn't been connected yet?
        // should we worry about that?
        
        conn = [[[LBIMAPConnection alloc] initWithAccount:account] autorelease];
        
        
    }
    
    if (!conn) {
        NSLog(@"Could not connect to server");
        return nil;
    }
    
    [conn setDebugOutput:[LBPrefs boolForKey:@"debugIMAPMessages"]];
    
    [activeIMAPConnections addObject:conn];
    
    return conn;
}

- (void)checkInIMAPConnection:(LBIMAPConnection*) conn {
    
    if (![[NSThread currentThread] isMainThread]) {
        
        dispatch_sync(dispatch_get_main_queue(),^ {
            [self checkInIMAPConnection:conn];
        });
        
        return;
    }
    
    // Possible solution- only ever checkout / check in on main thread?
    
    [conn setShouldCancelActivity:NO];
    
    [inactiveIMAPConnections addObject:conn];
    [activeIMAPConnections removeObject:conn];
    [conn setActivityStatusAndNotifiy:nil];
}



#define CheckConnectionAndReturnIfCanceled(aConn) { if (aConn.shouldCancelActivity) { dispatch_async(dispatch_get_main_queue(),^ { [self checkInIMAPConnection:conn]; }); return; } }


- (void)connectUsingBlock:(void (^)(NSError *))block {
    
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    
    if (!conn) {
        
        NSError *err = nil;
        
        LBQuickError(&err, @"Conect", 0, NSLocalizedString(@"Could not connect to server.", @"Could not connect to server."));
        
        block(err);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        [conn setActivityStatusAndNotifiy:NSLocalizedString(@"Connecting", @"Connecting")];
        
        [conn connectUsingBlock:^(NSError *err) {
        
            if (err) {
                // FIXME: do something nice if we don't connect to the server.
                NSLog(@"Could not connect to server");
                NSBeep();
                [self checkInIMAPConnection:conn];
                return;
            }
            
            [conn setActivityStatusAndNotifiy:NSLocalizedString(@"Logging in", @"Logging in")];
            
            [conn loginWithUsername:[[self account] username] password:[[self account] password] block:^(NSError *err) {
                
                [self checkInIMAPConnection:conn];
                
                // by default, select the inbox.
                [conn selectMailbox:@"INBOX" block:^(NSError *err) {
                    block(err);
                }];
            }];
        }];
    });
}

- (void)pullMessageFromServerFromList:(NSMutableArray*)messageList mailbox:(NSString*)mailbox mailboxList:(NSMutableArray*)mailboxList {
    
    // FIXME: should we check first to see if we've got the right box selected?
    
    if (![messageList count]) {
        // hey, we're all done!
        
        dispatch_async(dispatch_get_main_queue(),^ {
        
            [foldersCache removeObjectForKey:mailbox];
        
            [[NSNotificationCenter defaultCenter] postNotificationName:LBServerSubjectsUpdatedNotification
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:mailbox forKey:@"folderPath"]];
        });
        
        [messageList autorelease];
        
        [self checkForMailInMailboxList:mailboxList];
        
        return;
    }
    
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    // take one down, pass it around.  Ninety nine messages on the wall.
    NSString *firstId = [[[messageList objectAtIndex:0] retain] autorelease];
    [messageList removeObjectAtIndex:0];
    
    
    NSString *status = NSLocalizedString(@"%ld bottles of beer on the wall.  %ld bottles to go. (%@)", @"%ld bottles of beer on the wall.  %ld bottles to go. (%@)");
    [conn setActivityStatusAndNotifiy:[NSString stringWithFormat:status, [messageList count], [messageList count], mailbox]];
    
    
    [conn fetchMessages:firstId withBlock:^(NSError *err) {
        
        NSData *d = [conn lastFetchedMessage];
        
        [self saveMessageToCache:d forMailbox:mailbox ];
        
        //NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
        
        [self checkInIMAPConnection:conn];
        [self pullMessageFromServerFromList:messageList mailbox:mailbox mailboxList:mailboxList];
    }];
}

- (void)checkForMailInMailboxList:(NSMutableArray*)mailboxList {
    
    if (![mailboxList count]) {
        // hey, we're all done!
        [mailboxList autorelease];
        return;
    }
    
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    
    
    // start at the top.
    NSString *mailbox = [[[mailboxList objectAtIndex:0] retain] autorelease];
    [mailboxList removeObjectAtIndex:0];
    
    NSString *status = NSLocalizedString(@"Finding messages in '%@'", @"Finding messages in '%@'");
    [conn setActivityStatusAndNotifiy:[NSString stringWithFormat:status, mailbox]];
    
    NSURL *mailboxURL = [accountCacheURL URLByAppendingPathComponent:mailbox];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[mailboxURL path]]) {
        NSError *err = nil;
        BOOL madeDir = [[NSFileManager defaultManager] createDirectoryAtPath:[mailboxURL path]
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&err];
        if (err || !madeDir) {
            // FIXME: do something sensible with this.
            NSLog(@"Error creating cache folder: %@ %@", [mailboxURL path], err);
        }
    }
    
    
    [conn selectMailbox:mailbox block:^(NSError *err) {
        
        if (err) {
            NSLog(@"Could not select mailbox %@", mailbox);
            NSLog(@"%@", err);
            [self checkInIMAPConnection:conn];
            [self checkForMailInMailboxList:mailboxList];
            return;
        }
        
        [conn listMessagesWithBlock:^(NSError *err) {
            
            [self checkInIMAPConnection:conn];
            
            if (err) {
                NSLog(@"Could not list messages mailbox %@", mailbox);
                NSLog(@"%@", err);
                [self checkForMailInMailboxList:mailboxList];
                return;
            }
            
            NSArray *messages = [conn searchedResultSet];
            
            if ([messages count]) {
                [self pullMessageFromServerFromList:[messages mutableCopy] mailbox:mailbox mailboxList:mailboxList];
            }
            else {
                [self checkForMailInMailboxList:mailboxList];
            }
        }];
    }];
    
    debug(@"refreshing mailbox: %@", mailbox);
}

- (void)checkForMail {
    
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        // FIXME: check for a connected object.
        
        CheckConnectionAndReturnIfCanceled(conn);
        
        [conn setActivityStatusAndNotifiy:NSLocalizedString(@"Updating folder list", @"Updating folder list")];
        
        [conn listSubscribedMailboxesWithBock:^(NSError *err) {
            
            NSMutableArray *mailboxNames = [NSMutableArray array];
            NSArray *mailboxes = [conn fetchedMailboxes];
            
            for (NSDictionary *mailboxInfo in mailboxes) {
                NSString *name = [mailboxInfo objectForKey:@"mailboxName"];
                [mailboxNames addObject:name];
            }
            
            [mailboxNames sortUsingSelector:@selector(localizedStandardCompare:)];
            
            [self setFoldersList:mailboxNames];
            
            [self saveFoldersToCache:foldersList];
            
            CheckConnectionAndReturnIfCanceled(conn);
            
            dispatch_async(dispatch_get_main_queue(),^ {
                
                [self checkInIMAPConnection:conn];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LBServerFolderUpdatedNotification
                                                                    object:self
                                                                  userInfo:nil];
                
                // we'll release this guy when we're it's down to zilch.
                [self checkForMailInMailboxList:[mailboxNames mutableCopy]];
            });
        }];
        
        
        /*
        
        
        for (NSString *folderPath in list) {
            
            CheckConnectionAndReturnIfCanceled(conn);
            
            NSString *status = NSLocalizedString(@"Finding messages in '%@'", @"Finding messages in '%@'");
            [conn setActivityStatusAndNotifiy:[NSString stringWithFormat:status, folderPath]];
            
            LBFolder *folder    = [[LBFolder alloc] initWithPath:folderPath inIMAPConnection:conn];
            
            NSSet *messageSet   = [folder messageObjectsFromIndex:1 toIndex:0]; 
            
            if (!messageSet || ![folder connected]) {
                NSLog(@"Could not get folder listing for %@", list);
                [folder release];
                continue;
            }
            
            
            NSArray *messages = [[messageSet allObjects] sortedArrayUsingComparator:^(LBMessage *obj1, LBMessage *obj2) {
                // FIXME: sort by date or something, not subject.
                return [[obj1 subject] localizedCompare:[obj2 subject]];
            }];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                
                [foldersCache setObject:messages forKey:folderPath];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:LBServerSubjectsUpdatedNotification
                                                                    object:self
                                                                  userInfo:[NSDictionary dictionaryWithObject:folderPath
                                                                                                       forKey:@"folderPath"]];
            });
            
            NSInteger idx = 0;
            
            for (LBMessage *msg in messages) {
                
                CheckConnectionAndReturnIfCanceled(conn);
                
                idx++;
                
                NSString *status = NSLocalizedString(@"Loading message %d of %d messages in '%@'", @"Loading message %d of %d messages in '%@'");
                [conn setActivityStatusAndNotifiy:[NSString stringWithFormat:status, idx, [messages count], folderPath]];
                
                char *result;
                size_t messageLen;
                int err = mailmessage_fetch([msg messageStruct], &result, &messageLen);
                if (err) {
                    debug(@"error with mailmessage_fetch %d", err);
                    continue;
                }
                
                debug(@"msg: %@", [msg uid]);
                NSString *content = [[NSString alloc] initWithBytes:result length:messageLen encoding:NSASCIIStringEncoding];
                
                [self saveMessageToCache:msg body:content forFolder:folderPath];
                
            }
            
            dispatch_async(dispatch_get_main_queue(),^ {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBServerBodiesUpdatedNotification
                                                                    object:self
                                                                  userInfo:[NSDictionary dictionaryWithObject:folderPath forKey:@"folderPath"]];
            });
            
            [folder release];
            
        }
        
        
        
        */
        
        
    });
    
}

- (NSArray*)messageListForPath:(NSString*)folderPath {
    
    
    if (![foldersCache objectForKey:folderPath]) {
        
        NSArray *msgList = [self cachedMessagesForFolder:folderPath];
        
        [foldersCache setObject:msgList forKey:folderPath];
    }
    
    
    return [foldersCache objectForKey:folderPath];
}

- (void)deleteMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block {
    
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        [conn deleteMessages:seqIds withBlock:^(NSError *err) {
            [self checkInIMAPConnection:conn];
            block(err);
        }];
    });
    
}

- (void)expungeWithBlock:(LBResponseBlock)block {
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        [conn expungeWithBlock:^(NSError *err) {
            [self checkInIMAPConnection:conn];
            block(err);
        }];
    });
}
- (void)moveMessages:(NSArray*)messageList inFolder:(NSString*)currentFolder toFolder:(NSString*)folder finshedBlock:(LBResponseBlock)block {
    
    /*
    // FIXME: we need a way have this guy auto log in in.
    LBIMAPConnection *conn = [self checkoutIMAPConnection];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        BOOL success = YES;
        NSError *err = nil;
        
        int mr = mailimap_select([conn session], [currentFolder UTF8String]);
        
        // uhhhhhh
        
        //struct mailimap_set *set = mailimap_set_new_empty(void);
        //struct mailimap_set_item
        
        NSMutableArray *messageIdList = [NSMutableArray array];
        
        for (LBMessage *message in messageList) {
            [messageIdList addObject:[NSNumber numberWithUnsignedLong:[message sequenceNumber]]];
        }
        
        debug(@"messageIdList: %@", messageIdList);
        
        struct mailimap_set *set = setFromArray(messageIdList);
        
        mr = mailimap_uid_copy([conn session], set, [folder UTF8String]);
        
        //int mailimap_copy([conn session], struct mailimap_set * set, const char * mb);
        
        
        
        
        
        dispatch_async(dispatch_get_main_queue(),^ {
            [self checkInIMAPConnection:conn];
        });
        
        if (block) {
            dispatch_async(dispatch_get_main_queue(),^ {
                
                block(success, err);
                
                [self checkInIMAPConnection:conn];
            });
        }
        
    });
    */
    
}


- (void)makeCacheFolders {
    
    NSError *err = nil;
    BOOL madeDir = [[NSFileManager defaultManager] createDirectoryAtPath:[accountCacheURL path]
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&err];
    if (err || !madeDir) {
        // FIXME: do something sensible with this.
        NSLog(@"Error creating cache folder: %@", err);
    }
}

- (void)loadCache {
    
    assert(baseCacheURL);
    assert(account);
    
    NSString *cacheFolder = [NSString stringWithFormat:@"imap-%@@%@.letterbox", [account username], [account imapServer]];
    
    self.accountCacheURL  = [baseCacheURL URLByAppendingPathComponent:cacheFolder];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[accountCacheURL path]]) {
        [self makeCacheFolders];
    }
    
    NSString *databasePath = [[accountCacheURL URLByAppendingPathComponent:@"letterscache.db"] path];
    
    cacheDB = [[FMDatabase databaseWithPath:databasePath] retain];
    
    if (![cacheDB open]) {
        NSLog(@"Can't open the %@!", cacheFolder);
        // FIXME: do something nice here for the user.
        [cacheDB release];
        cacheDB = nil;
        return;
    }
    
    // now we setup some tables.
    
    FMResultSet *rs = [cacheDB executeQuery:@"select name from SQLITE_MASTER where name = 'letters_meta'"];
    
    if (![rs next]) {
        debug(@"setting up new tables.");
        [rs close];
        // if we don't get a result, then we'll need to make our tables.
        
        int schemaVersion = 1;
        
        [cacheDB beginTransaction];
        
        // simple key value stuff, for config info.  The type is the value type.  Eventually i'll add something like:
        // - (void) setDBProperty:(id)obj forKey:(NSString*)key
        // - (id) dbPropertyForKey:(NSString*)key
        // which just figures out what the type is, and stores it appropriately.
        
        [cacheDB executeUpdate:@"create table letters_meta ( name text, type text, value blob )"];
        
        [cacheDB executeUpdate:@"insert into letters_meta (name, type, value) values (?,?,?)", @"schemaVersion", @"int", [NSNumber numberWithInt:schemaVersion]];
        
        // this table obviously isn't going to cut it.  It needs multiple to's and other nice things.
        [cacheDB executeUpdate:@"create table message ( uuid text primary key,\n\
                                                   messageid text,\n\
                                                   folder text,\n\
                                                   subject text,\n\
                                                   fromAddress text, \n\
                                                   toAddress text, \n\
                                                   receivedDate float,\n\
                                                   sendDate float\n\
                                                 )"];
        
        // um... do we need anything else?
        [cacheDB executeUpdate:@"create table folder ( folder text, subscribed int )"];
        
        [cacheDB commit];
    }
    [rs close];
    
    NSMutableArray *newFolders = [NSMutableArray array];
    
    rs = [cacheDB executeQuery:@"select folder from folder"];
    while ([rs next]) {
        [newFolders addObject:[rs stringForColumnIndex:0]];
    }
    
    [self setFoldersList:[newFolders sortedArrayUsingSelector:@selector(localizedStandardCompare:)]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LBServerFolderUpdatedNotification
                                                        object:self
                                                      userInfo:nil];
    
    
    
}

- (void)saveMessageToCache:(NSData*)messageData forMailbox:(NSString*)mailboxName {
    
    NSURL *folderURL = [accountCacheURL URLByAppendingPathComponent:mailboxName];
    
    NSDictionary *simpleHeaders = LBSimpleMesageHeaderSliceAndDice(messageData);
    
    NSString *msgId = [[simpleHeaders objectForKey:@"message-id"] lastObject];
    
    if (!msgId) {
        // FIXME: do something nicer here.
        NSLog(@"There's no message id for this message.");
        
        debug(@"messageData: %@", [[[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding] autorelease]);
        
        return;
    }
    
    NSString *messageFile = [NSString stringWithFormat:@"%s.letterboxmsg", [msgId fileSystemRepresentation]];
    
    NSURL *messageCacheURL = [folderURL URLByAppendingPathComponent:messageFile];
    
    NSError *err = nil;
    
    if (![messageData writeToURL:messageCacheURL options:0 error:&err]) {
        NSLog(@"Could not write to %@", messageCacheURL);
        NSLog(@"err: %@", err);
    }
    
    // FIXME: the dates are allllllll wrong.
    // FIXME: we'd probably get better perf. with batches.
    
    NSString *subject   = [[simpleHeaders objectForKey:@"subject"] lastObject];
    NSString *from      = [[simpleHeaders objectForKey:@"from"] lastObject];
    NSString *to        = [[simpleHeaders objectForKey:@"to"] lastObject];
    
    [cacheDB beginTransaction];
    
    // this feels icky.
    [cacheDB executeUpdate:@"delete from message where messageId = ?", msgId];
    
    [cacheDB executeUpdate:@"insert into message ( messageid, folder, subject, fromAddress, toAddress, receivedDate, sendDate) values (?, ?, ?, ?, ?, ?, ?)",
                                msgId, mailboxName, subject, from, to, [NSDate distantFuture], [NSDate distantPast]];
    
    [cacheDB commit];
}

// FIXME: need to setup a way to differentiate between subscribed and non subscribed.
- (void)saveFoldersToCache:(NSArray*)messages {
    
    [cacheDB beginTransaction];
    
    // this is pretty lame.
    [cacheDB executeUpdate:@"delete from folder"];
    
    for (NSString *folder in messages) {
        [cacheDB executeUpdate:@"insert into folder (folder, subscribed) values (?,1)", folder];
    }
    
    [cacheDB commit];
    
}

- (NSArray*)cachedMessagesForFolder:(NSString *)folder {
    
    NSMutableArray *messageArray = [NSMutableArray array];
    
    FMResultSet *rs = [cacheDB executeQuery:@"select uuid, messageid, subject, fromAddress, toAddress, receivedDate, sendDate from message where folder = ? order by receivedDate", folder];
    while ([rs next]) {
        
        NSString *messageFile = [NSString stringWithFormat:@"%s.letterboxmsg", [[rs stringForColumnIndex:1] fileSystemRepresentation]];
        
        NSURL *messageCacheURL = [[accountCacheURL URLByAppendingPathComponent:folder] URLByAppendingPathComponent:messageFile];
        
        LBMessage *message = [[[LBMessage alloc] initWithURL:messageCacheURL] autorelease];
        
        if (!message) {
            NSLog(@"Could not load message at %@", messageCacheURL);
            continue;
        }
        
        message.uuid = [rs stringForColumnIndex:0];
        message.messageId = [rs stringForColumnIndex:1];
        message.subject = [rs stringForColumnIndex:2];
        message.sender = [rs stringForColumnIndex:3];
        message.to = [rs stringForColumnIndex:4];
        message.receivedDate = [rs dateForColumnIndex:5];
        message.sendDate = [rs dateForColumnIndex:6];
        
        [messageArray addObject:message];
    }
    
    return messageArray;
    
}





@end