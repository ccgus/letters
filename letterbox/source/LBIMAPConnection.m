//
//  LBIMAPConnection.m
//  LetterBox
//
//  Created by August Mueller on 1/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBIMAPConnection.h"
#import "LBAccount.h"
#import "LetterBoxTypes.h"
#import "LBFolder.h"
#import "LBAddress.h"
#import "LBMessage.h"
#import "LetterBoxUtilities.h"

@implementation LBIMAPConnection
@synthesize shouldCancelActivity;

- (id) init {
    
	self = [super init];
	if (self != nil) {
		
        connected          = NO;
        storage            = mailstorage_new(NULL);
        
        assert(storage != NULL);
	}
    
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    mailstorage_disconnect(storage);
    mailstorage_free(storage);
    [super dealloc];
}


- (BOOL)isConnected {
    return connected;
}

- (BOOL) connectWithAccount:(LBAccount*)account error:(NSError**)outErr {
    
    int err = 0;
    int imap_cached = 0;
    
    const char* auth_type_to_pass = NULL;
    if(account.authType == IMAP_AUTH_TYPE_SASL_CRAM_MD5) {
        auth_type_to_pass = "CRAM-MD5";
    }
    
    err = imap_mailstorage_init_sasl(storage,
                                     (char *)[[account imapServer] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (uint16_t)[account imapPort],
                                     NULL,
                                     [account connectionType],
                                     auth_type_to_pass,
                                     NULL,
                                     NULL, NULL,
                                     (char *)[[account username] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (char *)[[account username] cStringUsingEncoding:NSUTF8StringEncoding],
                                     (char *)[[account password] cStringUsingEncoding:NSUTF8StringEncoding],
                                     NULL,
                                     imap_cached,
                                     NULL);
    
    if (err != MAIL_NO_ERROR) {
        LBQuickError(outErr, LBMemoryError, err, LBMemoryErrorDesc);
        return NO;
    }
    
    err = mailstorage_connect(storage);
    
    if (err == MAIL_ERROR_LOGIN) {
        LBQuickError(outErr, LBLoginError, err, LBLoginErrorDesc);
        return NO;
    }
    else if (err != MAIL_NO_ERROR) {
        LBQuickError(outErr, LBUnknownError, err, [NSString stringWithFormat:@"Error number: %d",err]);
        return NO;
    }
    
    connected = YES;
    
    return connected;
}


- (void) disconnect {
    connected = NO;
    mailstorage_disconnect(storage);
}

- (LBFolder *)folderWithPath:(NSString *)path {
    LBFolder *folder = [[LBFolder alloc] initWithPath:path inIMAPConnection:self];
    return [folder autorelease];
}



- (mailimap *)session {
    struct imap_cached_session_state_data * cached_data;
    struct imap_session_state_data * data;
    mailsession *session;
    
    session = storage->sto_session;
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
    return storage;
}



- (NSArray *) subscribedFolderNames:(NSError**)outErr {
    struct mailimap_mailbox_list * mailboxStruct;
    clist *subscribedList;
    clistiter *cur;
    
    NSString *mailboxNameObject;
    char *mailboxName;
    int err;
    
    NSMutableArray *subscribedFolders = [NSMutableArray array];   
    
    //Fill the subscribed folder array
    err = mailimap_lsub([self session], "", "*", &subscribedList);
    if (err != MAIL_NO_ERROR) {
        LBQuickError(outErr, LBUnknownError, err, [NSString stringWithFormat:@"Error number: %d",err]);
        return nil;
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
    
    if (![subscribedFolders containsObject:@"INBOX"]) {
        // we're alwasy going to have an inbox.  I'm looking at you MobileMe
        [subscribedFolders addObject:@"INBOX"];
    }
    
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

- (int) activityType {
    return 0;
}

- (void)setActivityStatusAndNotifiy:(NSString *)value {
    if (activityStatus != value) {
        
        BOOL isNew  = (value && !activityStatus);
        BOOL isOver = (!value) && activityStatus;
        
        [activityStatus release];
        activityStatus = [value retain];
        
        dispatch_async(dispatch_get_main_queue(),^ {
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self forKey:@"activity"];
            
            if (isNew) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityStartedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            else if (isOver) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityEndedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityUpdatedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            
        });
        
    }
}



- (NSString*) activityStatus {
    return activityStatus;
}

- (void) cancelActivity {
    shouldCancelActivity = YES;
    [self setActivityStatusAndNotifiy:NSLocalizedString(@"Canceling…", @"Canceling…")];
}

@end
