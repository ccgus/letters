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
#import "LBFolder.h"
#import "LBAddress.h"
#import "LBMessage.h"
#import "FMDatabase.h"

@implementation LBServer
@synthesize account=_account;
@synthesize baseCacheURL=_baseCacheURL;
@synthesize accountCacheURL=_accountCacheURL;

- (id) initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL {
    
	self = [super init];
	if (self != nil) {
		self.account        = anAccount;
        self.baseCacheURL   = cacheFileURL;
        _connected          = NO;
        _storage            = mailstorage_new(NULL);
        
        assert(_storage != NULL);
	}
    
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_account release];
    [_baseCacheURL release];
    [_accountCacheURL release];
    [_cacheDB release];
    
    mailstorage_disconnect(_storage);
    mailstorage_free(_storage);
    [super dealloc];
}

- (void) makeCacheFolders {
    
    debug(@"[_accountCacheURL path]: %@", [_accountCacheURL path]);
    
    NSError *err = nil;
    BOOL madeDir = [[NSFileManager defaultManager] createDirectoryAtPath:[_accountCacheURL path]
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&err];
    if (err || !madeDir) {
        // FIXME: do something sensible with this.
        NSLog(@"Error creating cache folder: %@", err);
    }
    
}

- (void) loadCache {
    
    assert(_baseCacheURL);
    assert(_account);
    
    
    NSString *cacheFolder = [NSString stringWithFormat:@"imap-%@@%@.letterbox", [_account username], [_account imapServer]];
    
    self.accountCacheURL  = [_baseCacheURL URLByAppendingPathComponent:cacheFolder];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[_accountCacheURL path]]) {
        [self makeCacheFolders];
    }
    
    NSString *databasePath = [[_accountCacheURL URLByAppendingPathComponent:@"letterscache.db"] path];
    
    debug(@"databasePath: %@", databasePath);
    
    _cacheDB = [[FMDatabase databaseWithPath:databasePath] retain];
    
    if (![_cacheDB open]) {
        NSLog(@"Can't open the %@!", cacheFolder);
        // FIXME: do something nice here for the user.
        [_cacheDB release];
        _cacheDB = nil;
        return;
    }
    
    // now we setup some tables.
    
    FMResultSet *rs = [_cacheDB executeQuery:@"select name from SQLITE_MASTER where name = 'letters_meta'"];
    
    
    if (![rs next]) {
        debug(@"setting up new tables.");
        [rs close];
        // if we don't get a result, then we'll need to make our tables.
        
        int schemaVersion = 1;
        
        [_cacheDB beginTransaction];
        
        // simple key value stuff, for config info.  The type is the value type.  Eventually i'll add something like:
        // - (void) setDBProperty:(id)obj forKey:(NSString*)key
        // - (id) dbPropertyForKey:(NSString*)key
        // which just figures out what the type is, and stores it appropriately.
        
        [_cacheDB executeUpdate:@"create table letters_meta ( name text, type text, value blob )"];
        
        [_cacheDB executeUpdate:@"insert into letters_meta (name, type, value) values (?,?,?)", @"schemaVersion", @"int", [NSNumber numberWithInt:schemaVersion]];
        
        // this table obviously isn't going to cut it.  It needs multiple to's and other nice things.
        [_cacheDB executeUpdate:@"create table message ( messageid text primary key,\n\
                                                   folder text,\n\
                                                   subject text,\n\
                                                   fromAddress text, \n\
                                                   toAddress text, \n\
                                                   receivedDate float,\n\
                                                   sendDate float\n\
                                                 )"];
        
        // um... do we need anything else?
        [_cacheDB executeUpdate:@"create table folder ( folder text, subscribed int )"];
        
        [_cacheDB commit];
    }
}

- (void) saveMessagesToCache:(NSSet*)messages forFolder:(NSString*)folderName {
    
    [_cacheDB beginTransaction];
    
    // FIXME - the dates are allllllll off.
    
    // this feels icky.
    [_cacheDB executeUpdate:@"delete from message where folder = ?", folderName];
    
    for (LBMessage *msg in messages) {
        [_cacheDB executeUpdate:@"insert into message ( messageid, folder, subject, fromAddress, toAddress, receivedDate, sendDate) values (?, ?, ?, ?, ?, ?, ?)",
                                [msg messageId], folderName, [msg subject], [[[msg from] anyObject] email], [[[msg to] anyObject] email], [NSDate distantFuture], [NSDate distantPast]];
    }
    
    [_cacheDB commit];
    
    // we do this outside the transaction so that we don't hold up the db.
    
    NSURL *folderURL = [_accountCacheURL URLByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[folderURL path]]) {
        NSError *err = nil;
        BOOL madeDir = [[NSFileManager defaultManager] createDirectoryAtPath:[folderURL path]
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&err];
        if (err || !madeDir) {
            // FIXME: do something sensible with this.
            NSLog(@"Error creating cache folder: %@ %@", [folderURL path], err);
        }
    }
    
    for (LBMessage *msg in messages) {
        
        // FIXME: some way to fail gracefully?
        
        NSString *messageFile = [NSString stringWithFormat:@"%@.letterboxmsg", [msg messageId]];
        
        NSURL *messageCacheURL = [folderURL URLByAppendingPathComponent:messageFile];
        
        [msg writePropertyListRepresentationToURL:messageCacheURL];
    }
}

// FIXME: need to setup a way to differentiate between subscribed and non subscribed.
- (void) saveFoldersToCache:(NSArray*)messages {
    
    [_cacheDB beginTransaction];
    
    // this is pretty lame.
    [_cacheDB executeUpdate:@"delete from folder"];
    
    for (NSString *folder in messages) {
        [_cacheDB executeUpdate:@"insert into folder (folder, subscribed) values (?,1)", folder];
    }
    
    [_cacheDB commit];
}

// FIXME: why am I returning strings here and not a LBFolder of some sort?

- (NSArray*) cachedFolders {
    
    NSMutableArray *array = [NSMutableArray array];
    
    FMResultSet *rs = [_cacheDB executeQuery:@"select folder from folder"];
    while ([rs next]) {
        [array addObject:[rs stringForColumnIndex:0]];
    }
    
    return [array sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
}

- (NSArray*) cachedMessagesForFolder:(NSString *)folder {
    
    NSMutableArray *messageArray = [NSMutableArray array];
    
    FMResultSet *rs = [_cacheDB executeQuery:@"select messageid, receivedDate from message where folder = ? order by receivedDate", folder];
    while ([rs next]) {
        
        NSString *messageFile = [NSString stringWithFormat:@"%@.letterboxmsg", [rs stringForColumnIndex:0]];
        
        // FIXME: check for the existence of the file...
        
        NSURL *messageCacheURL = [[_accountCacheURL URLByAppendingPathComponent:folder] URLByAppendingPathComponent:messageFile];
        
        LBMessage *message = [[[LBMessage alloc] init] autorelease];
        
        // FIXME: this isn't thread safe. (the file manager)
        if ([[NSFileManager defaultManager] fileExistsAtPath:[messageCacheURL path]]) {
            
            [message loadPropertyListRepresentationFromURL:messageCacheURL];
            
            [messageArray addObject:message];
        }
        else {
            // FIXME: make a list of messages to remove from the cache, as the FS rep isn't around.
        }
        
    }
    
    return messageArray;
}

- (BOOL)isConnected {
    return _connected;
}


- (void) connect {
    
    int err = 0;
    int imap_cached = 0;
    
    const char* auth_type_to_pass = NULL;
    if(_account.authType == IMAP_AUTH_TYPE_SASL_CRAM_MD5) {
        auth_type_to_pass = "CRAM-MD5";
    }
    
    err = imap_mailstorage_init_sasl(_storage,
                                     (char *)[[_account imapServer] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (uint16_t)[_account imapPort],
                                     NULL,
                                     [_account connectionType],
                                     auth_type_to_pass,
                                     NULL,
                                     NULL, NULL,
                                     (char *)[[_account username] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (char *)[[_account username] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (char *)[[_account password] cStringUsingEncoding:NSUTF8StringEncoding],
                                     NULL,
                                     imap_cached,
                                     NULL);
    
    // FIXME: don't throw an exception here.  return an NSError* instead.  Same with the other exceptions.
    
    if (err != MAIL_NO_ERROR) {
        NSException *exception = [NSException exceptionWithName:LBMemoryError
                                                         reason:LBMemoryErrorDesc
                                                       userInfo:nil];
        [exception raise];
    }
    
    err = mailstorage_connect(_storage);
    if (err == MAIL_ERROR_LOGIN) {
        NSException *exception = [NSException exceptionWithName:LBLoginError
                                                         reason:LBLoginErrorDesc
                                                       userInfo:nil];
        [exception raise];
    }
    else if (err != MAIL_NO_ERROR) {
        NSException *exception = [NSException exceptionWithName:LBUnknownError
                                                         reason:[NSString stringWithFormat:@"Error number: %d",err]
                                                       userInfo:nil];
        [exception raise];
    }
    else {
        _connected = YES;
    }
}


- (void) disconnect {
    _connected = NO;
    mailstorage_disconnect(_storage);
}

- (LBFolder *)folderWithPath:(NSString *)path {
    LBFolder *folder = [[LBFolder alloc] initWithPath:path inServer:self];
    return [folder autorelease];
}


- (mailimap *)session {
    struct imap_cached_session_state_data * cached_data;
    struct imap_session_state_data * data;
    mailsession *session;
    
    session = _storage->sto_session;
    if(session == nil) {
        return nil;
    }
    
    if (strcasecmp(session->sess_driver->sess_name, "imap-cached") == 0) {
        cached_data = session->sess_data;
        session = cached_data->imap_ancestor;
    }
    
    data = session->sess_data;
    return data->imap_session;
}


- (struct mailstorage *)storageStruct {
    return _storage;
}


- (NSArray *) subscribedFolders {
    struct mailimap_mailbox_list * mailboxStruct;
    clist *subscribedList;
    clistiter *cur;
    
    NSString *mailboxNameObject;
    char *mailboxName;
    int err;
    
    NSMutableArray *subscribedFolders = [NSMutableArray array];   
    
    // FIXME: get rid of this exception below.
    
    //Fill the subscribed folder array
    err = mailimap_lsub([self session], "", "*", &subscribedList);
    if (err != MAIL_NO_ERROR) {
        NSException *exception = [NSException exceptionWithName:LBUnknownError
                                                         reason:[NSString stringWithFormat:@"Error number: %d",err]
                                                       userInfo:nil];
        [exception raise];
    }
    /*
    else if (clist_isempty(subscribedList)) {
        // pft.
    }
    */
    
    for(cur = clist_begin(subscribedList); cur != NULL; cur = cur->next) {
        mailboxStruct = cur->data;
        mailboxName = mailboxStruct->mb_name;
        mailboxNameObject = [NSString stringWithCString:mailboxName encoding:NSUTF8StringEncoding];
        [subscribedFolders addObject:mailboxNameObject];
    }
    
    mailimap_list_result_free(subscribedList);
    
    if (![subscribedFolders count]) {
        // we're alwasy going to have an inbox.  I'm looking at you MobileMe
        [subscribedFolders addObject:@"INBOX"];
    }
    
    [self saveFoldersToCache:subscribedFolders];
    
    return [subscribedFolders sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
}

- (NSArray *)allFolders {
    struct mailimap_mailbox_list * mailboxStruct;
    clist *allList;
    clistiter *cur;
    
    NSString *mailboxNameObject;
    char *mailboxName;
    int err;
    
    NSMutableArray *allFolders = [NSMutableArray array];
    
    //Now, fill the all folders array
    //TODO Fix this so it doesn't use *
    err = mailimap_list([self session], "", "*", &allList);     
    if (err != MAIL_NO_ERROR) {
        NSException *exception = [NSException exceptionWithName:LBUnknownError
                                                         reason:[NSString stringWithFormat:@"Error number: %d",err]
                                                       userInfo:nil];
        [exception raise];
    }
    else if (clist_isempty(allList)) {
        NSException *exception = [NSException exceptionWithName:LBNoFolders
                                                         reason:LBNoFoldersDesc
                                                       userInfo:nil];
        [exception raise];
    }
    for(cur = clist_begin(allList); cur != NULL; cur = cur->next) {
        mailboxStruct = cur->data;
        mailboxName = mailboxStruct->mb_name;
        mailboxNameObject = [NSString stringWithCString:mailboxName encoding:NSUTF8StringEncoding];
        [allFolders addObject:mailboxNameObject];
    }
    mailimap_list_result_free(allList);
    
    return [allFolders sortedArrayUsingSelector:@selector(localizedStandardCompare:)];

}


@end
