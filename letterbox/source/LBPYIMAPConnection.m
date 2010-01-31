//
//  LBPYIMAPConnection.m
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBPYIMAPConnection.h"
#import "LBAccount.h"
#import "LetterBoxTypes.h"
#import "LBFolder.h"
#import "LBAddress.h"
#import "LBMessage.h"
#import "LetterBoxUtilities.h"
#import <Python/Python.h>


extern int *_NSGetArgc(void);
extern char ***_NSGetArgv(void);

static BOOL LBPYIMAPConnectionPythonLoaded;

@interface IMAPFetcher
-(void)doSomething;
-(void)setAccount:(LBAccount*)anAccount;
-(void)setAccountFolder:(NSString*)pathToFolder;
-(BOOL)connect;
-(NSArray*)folderNames;
-(NSArray*)messagesInMailbox:(NSString*)mbox;
@end

@interface LBPYIMAPConnection ()
- (void)loadPython;
@end

@implementation LBPYIMAPConnection
@synthesize shouldCancelActivity;

- (id)init {
	self = [super init];
	if (self != nil) {
		
        if (!LBPYIMAPConnectionPythonLoaded) {
            [self loadPython];
        }
	}
	return self;
}

- (void)loadPython {
    
    NSBundle *myBundle      = [NSBundle bundleForClass:[self class]];
    NSString *mainFilePath  = [myBundle pathForResource:@"IMAPFetcher" ofType:@"py"];
    
    
    Py_SetProgramName("/usr/bin/python");
    Py_Initialize();
    PySys_SetArgv(*_NSGetArgc(), *_NSGetArgv());
    
    
    const char *mainFilePathPtr = [mainFilePath UTF8String];
    FILE *mainFile = fopen(mainFilePathPtr, "r");
    int result = PyRun_SimpleFile(mainFile, (char *)[[mainFilePath lastPathComponent] UTF8String]);
    
    if ( result != 0 ) {
        NSBeep();
        NSLog(@"%s:%d main() PyRun_SimpleFile failed with file '%@'.  See console for errors.", __FILE__, __LINE__, mainFilePath);
        return;
    }
    
    PyEval_SaveThread();
    
    Class c = NSClassFromString(@"IMAPFetcher");
    
    imapFetcher = [[c alloc] init];
    
    debug(@"imapFetcher: %@", imapFetcher);
    
    assert(imapFetcher);
    
    LBPYIMAPConnectionPythonLoaded = YES;
}




- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}


- (BOOL)isConnected {
    return connected;
}

- (BOOL) connectWithAccount:(LBAccount*)account error:(NSError**)outErr {
    
    [imapFetcher setAccount:account];
    
    connected = [imapFetcher connect];
    
    return connected;
}


- (void) disconnect {
    connected = NO;
    
    //mailstorage_disconnect(storage);
}


- (NSArray *) messagesInMailbox:(NSString*)mbox {
    
    NSArray *messageList = [imapFetcher messagesInMailbox:mbox];
    
    return messageList;
}


/*
- (LBFolder *)folderWithPath:(NSString *)path {
    LBFolder *folder = [[LBFolder alloc] initWithPath:path inIMAPConnection:self];
    return [folder autorelease];
}
*/

/*
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

*/

- (NSArray *) subscribedFolderNames:(NSError**)outErr {
    
    NSMutableArray *list = [NSMutableArray array];
    
    for (NSString *line in [imapFetcher folderNames]) {
        
        // this is obviously a hack.
        NSArray *comps = [line componentsSeparatedByString:@"\""];
        
        if ([comps count] > 2) {
            [list addObject:[comps objectAtIndex:[comps count] - 2]];
        }
    }
    
    return [list sortedArrayUsingSelector:@selector(localizedStandardCompare:)];;
}



@end


