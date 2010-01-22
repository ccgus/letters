//
//  LAMailViewController.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LAMailViewController.h"
#import "LAAppDelegate.h"

@implementation LAMailViewController
@synthesize folders=_folders;
@synthesize server=_server;

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
    [_messages release];
    [_folders release];
    [super dealloc];
}


- (void)awakeFromNib {
	
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
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
    
    debug(@"Loading cache messages");
    _messages = [[_server cachedMessagesForFolder:folder] mutableCopy];
    [mailboxMessageList reloadData];
    
    if (![_server isConnected]) {
        // FIXME: do something nice here.
        NSLog(@"Not connected!");
        return;
    }    
    
    [workingIndicator startAnimation:self];
    
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
            debug(@"updating with what's on the server.");
            [_messages removeAllObjects];
            [_messages addObjectsFromArray:[messageSet allObjects]];
            
            [mailboxMessageList reloadData];
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
            
            [[[messageTextView textStorage] mutableString] setString:[LAPrefs boolForKey:@"chocklock"] ? [[msg body] uppercaseString] : [msg body]];
        }
    }
    
    else if ([notification object] == foldersList) {
        NSUInteger selectedRow = [foldersList selectedRow];
        if (selectedRow >= 0) {
            
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


@end


