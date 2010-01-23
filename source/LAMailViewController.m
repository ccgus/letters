//
//  LAMailViewController.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LAMailViewController.h"
#import "LAAppDelegate.h"
#import "LADocument.h"

@implementation LAMailViewController
@synthesize folders=_folders;
@synthesize server=_server;
@synthesize statusMessage=_statusMessage;

+ (id) openNewMailViewController {
    
    LAMailViewController *me = [[LAMailViewController alloc] initWithWindowNibName:@"MailView"];
    
    return [me autorelease];
}

- (id) initWithWindowNibName:(NSString*)nibName {
	self = [super initWithWindowNibName:nibName];
	if (self != nil) {
		_messages = [[NSMutableArray alloc] init];
	}
    
	return self;
}


- (void)dealloc {
    [_statusMessage release];
    [_messages release];
    [_folders release];
    [super dealloc];
}


- (void)awakeFromNib {
	
    [mailboxMessageList setDataSource:self];
    [mailboxMessageList setDelegate:self];
    
    [foldersList setDataSource:self];
    [foldersList setDelegate:self];
}

- (NSURL*) cacheFolderURL {
    
    NSString *path = [@"~/Library/Letters/" stringByExpandingTildeInPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        NSError *err = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&err];
        if (err) {
            // FIXME: do something sensible with this.
            NSLog(@"Error creating cache folder: %@", err);
        }
    }
    
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

- (void) listFolder:(NSString*)folder {
    
    [_messages removeAllObjects];
    
    _messages = [[_server cachedMessagesForFolder:folder] mutableCopy];
    [mailboxMessageList reloadData];
    
    if (![_server isConnected]) {
        // FIXME: do something nice here.
        NSLog(@"Not connected!");
        return;
    }    
    
    [workingIndicator startAnimation:self];
    
    NSString *format = NSLocalizedString(@"Finding messages in %@", @"Finding messages in %@");
    [self setStatusMessage:[NSString stringWithFormat:format, folder]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^(void){
        
        // this needs to go somewhere else
        {
            NSMutableArray *folders = [NSMutableArray array];
            
            self.folders = [[[_server subscribedFolders] mutableCopy] autorelease];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                [foldersList reloadData];
            });
        }
        
        LBFolder *inbox   = [_server folderWithPath:folder];
        NSSet *messageSet = [inbox messageObjectsFromIndex:1 toIndex:0]; 
        
        dispatch_async(dispatch_get_main_queue(),^ {
            [_messages removeAllObjects];
            [_messages addObjectsFromArray:[messageSet allObjects]];
            
            [mailboxMessageList reloadData];
            
            [self setStatusMessage:NSLocalizedString(@"Download message bodies", @"Download message bodies")];
        });
        
        
        for (LBMessage *msg in messageSet) {
            [msg body]; // pull down the body. in the background.
        }
        
        dispatch_async(dispatch_get_main_queue(),^ {
            [self setStatusMessage:nil];
            [workingIndicator stopAnimation:self];
        });
    });
}

- (void) connectToServerAndList {
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    if (![[account password] length]) {
        [appDelegate openPreferences:nil];
        return;
    }
    
    [self setStatusMessage:NSLocalizedString(@"Connecting to server", @"Connecting to server")];
    
    // FIXME: this ivar shouldn't be here.  It probably belongs in the account?
    _server = [[LBServer alloc] initWithAccount:account usingCacheFolder:[self cacheFolderURL]];
    
    [_server loadCache]; // do this right away, so we can see our account info.  It's also kind of slow.
    
    // load our folder cache first.
    self.folders = [[[_server cachedFolders] mutableCopy] autorelease];
    [foldersList reloadData];
    
    [_server connect];
    
    [self listFolder:@"INBOX"];
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    if ([notification object] == mailboxMessageList) {
        NSInteger selectedRow = [mailboxMessageList selectedRow];
        if (selectedRow < 0) {
            [[[messageTextView textStorage] mutableString] setString:@"This area intentionally left blank."];
        }
        else {
            LBMessage *msg = [_messages objectAtIndex:selectedRow];
            
            NSString *message = nil;
            
            if ([msg messageDownloaded]) {
                message = [msg body];
            }
            else {
                message = NSLocalizedString(@"This message has not been downloaded from the server yet.", @"This message has not been downloaded from the server yet.");
            }
            
            message = [LAPrefs boolForKey:@"chocklock"] ? [message uppercaseString] : message;
            
            [[[messageTextView textStorage] mutableString] setString:message];
        }
    }
    
    else if ([notification object] == foldersList) {
        NSUInteger selectedRow = [foldersList selectedRow];
        
        // the real fix here is to not overwrite selected folders.
        if (selectedRow >= 0 && selectedRow < [_folders count] ) {
            
            NSString *folder = [_folders objectAtIndex:selectedRow];
            [self listFolder:folder];
        }
        
        
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    if (aTableView == foldersList) {
        return [_folders count];
    }
    
	return [_messages count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
    if (aTableView == foldersList) {
        // this will be taken out eventually.  But I just can't help myself.
        NSString *folderName = [_folders objectAtIndex:rowIndex];
        
        /*
        if ([folderName hasPrefix:@"INBOX."]) {
            folderName = [folderName substringFromIndex:6];
        }
        */
        
        return [LAPrefs boolForKey:@"chocklock"] ? [folderName uppercaseString] : folderName;
    }
    
    LBMessage *msg = [_messages objectAtIndex:rowIndex];
    
    NSString *identifier = [aTableColumn identifier];
    
    return [LAPrefs boolForKey:@"chocklock"] ? [[msg valueForKeyPath:identifier] uppercaseString] : [msg valueForKeyPath:identifier];

}

// FIXME: put this somewhere where it makes more sense, maybe a utils file?

NSString *FQuote(NSString *s) {
    NSMutableString *ret = [NSMutableString string];
    s = [s stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    for (NSString *line in [s componentsSeparatedByString:@"\n"]) {
        [ret appendFormat:@">%@\n", line];
    }
    return ret;
}

NSString *FRewrapLines(NSString *s, int len) {
    
    NSMutableString *ret = [NSMutableString string];
    
    
    s = [s stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    for (NSString *line in [s componentsSeparatedByString:@"\n"]) {
        
        if (![line length]) {
            [ret appendString:@"\n"];
            continue;
        }
        
        int idx = 0;
        
        while ((idx < [line length]) && ([line characterAtIndex:idx] == '>')) {
            idx++;
        }
        
        NSMutableString *pre = [NSMutableString string];
        
        for (int i = 0; i < idx; i++) {
            [pre appendString:@">"];
        }
        
        NSString *oldLine = [line substringFromIndex:idx];
        
        NSMutableString *newLine = [NSMutableString string];
        
        [newLine appendString:pre];
        
        for (NSString *word in [oldLine componentsSeparatedByString:@" "]) {
            
            if ([newLine length] + [word length] > len) {
                [ret appendString:newLine];
                [ret appendString:@"\n"];
                [newLine setString:pre];
            }
            
            if ([word length] && [newLine length]) {
                [newLine appendString:@" "];
            }
            
            [newLine appendString:word];
            
        }
        
        [ret appendString:newLine];
        [ret appendString:@"\n"];
        
    }
    
    return ret;
}




- (void) replyToSelectedMessage:(id)sender {
    
    NSInteger selectedRow = [mailboxMessageList selectedRow];
    
    if (selectedRow < 0) {
        // FIXME: we should validate the menu item.
        return;
    }
    
    LBMessage *msg = [_messages objectAtIndex:selectedRow];
    
    if (![msg messageDownloaded]) {
        // FIXME: validate for this case as well.
        return;
    }
    
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSError *err = nil;
    LADocument *doc = [dc openUntitledDocumentAndDisplay:YES error:&err];
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    debug(@"[account fromAddress]: %@", [account fromAddress]);
    
    [doc setFromList:[account fromAddress]];
    [doc setToList:[[msg sender] email]];
    
    debug(@"FRewrapLines([msg body], 72): %@", FRewrapLines([msg body], 72));
    
    // fixme - 72?  a pref maybe?
    [doc setMessage:FRewrapLines(FQuote([msg body]), 72)];
    
    NSString *subject = [msg subject];
    if (![[subject lowercaseString] hasPrefix:@"re: "]) {
        subject = [NSString stringWithFormat:@"Re: ", subject];
    }
    [doc setSubject:subject];
    
    [doc updateChangeCount:NSChangeDone];
}


@end


