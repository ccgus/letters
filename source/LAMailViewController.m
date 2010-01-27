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



@interface LAMailViewController ()
- (NSString *)selectedFolderPath;
@end


@implementation LAMailViewController

+ (id)openNewMailViewController {
    
    LAMailViewController *me = [[LAMailViewController alloc] initWithWindowNibName:@"MailView"];
    
    return [me autorelease];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [undoManager release];
    [super dealloc];
}


- (void)awakeFromNib {
    
    undoManager = [[NSUndoManager alloc] init];
    
    [mailboxMessageList setDataSource:self];
    [mailboxMessageList setDelegate:self];
    
    [foldersList setDataSource:self];
    [foldersList setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LBServerFolderUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
                                                  {
                                                      debug(@"folder list updated");
                                                      [foldersList reloadData];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LBServerSubjectsUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
                                                  {
                                                      debug(@"message list updated.");
                                                      NSString *selectedFolder = [self selectedFolderPath];
                                                      NSString *updatedFolder  = [[note userInfo] objectForKey:@"folderPath"];
                                                      if ([selectedFolder isEqualToString:updatedFolder]) {
                                                          [mailboxMessageList reloadData];
                                                      }
                                                  }];
    
}

- (NSUndoManager *)undoManager {
    return undoManager;
}

- (NSString *)selectedFolderPath {
    
    NSInteger selectedRow = [foldersList selectedRow];
    if (selectedRow < 0) {
        return @"INBOX";
    }
    else {
        LBAccount *currentAccount = [[appDelegate accounts] lastObject];
        return [[[currentAccount server] foldersList] objectAtIndex:selectedRow];        
    }
}

- (NSURL*)cacheFolderURL {
    
    NSString *path = [[LAPrefs stringForKey:@"cacheStoreFolder"] stringByExpandingTildeInPath];
    
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



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    if ([notification object] == mailboxMessageList) {
        NSInteger selectedRow = [mailboxMessageList selectedRow];
        if (selectedRow < 0) {
            [[[messageTextView textStorage] mutableString] setString:@"This area intentionally left blank."];
        }
        else {
            
            LBAccount *currentAccount = [[appDelegate accounts] lastObject];
            NSArray *messageList = [[currentAccount server] messageListForPath:[self selectedFolderPath]];
            
            LBMessage *msg = [messageList objectAtIndex:selectedRow];
            
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
        [mailboxMessageList reloadData];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    // just grab the last account.
    LBAccount *currentAccount = [[appDelegate accounts] lastObject];
    
    if (aTableView == foldersList) {
        return [[[currentAccount server] foldersList] count];
    }
    
    NSArray *messageList = [[currentAccount server] messageListForPath:[self selectedFolderPath]];
    
    return [messageList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    // just grab the last account.
    LBAccount *currentAccount = [[appDelegate accounts] lastObject];
    
    if (aTableView == foldersList) {
        
        NSString *folderName = [[[currentAccount server] foldersList] objectAtIndex:rowIndex];
        
        // this will be taken out eventually.  But I just can't help myself.  Please be quiet about it.
        return [LAPrefs boolForKey:@"chocklock"] ? [folderName uppercaseString] : folderName;
    }
    
    NSArray *messageList = [[currentAccount server] messageListForPath:[self selectedFolderPath]];
    
    LBMessage *msg = [messageList objectAtIndex:rowIndex];
    
    NSString *identifier = [aTableColumn identifier];
    
    return [LAPrefs boolForKey:@"chocklock"] ? [[msg valueForKeyPath:identifier] uppercaseString] : [msg valueForKeyPath:identifier];
    
}


- (void)moveLeft:(id)sender {
    if ([[self window] firstResponder] == mailboxMessageList) {
        [[self window] makeFirstResponder:foldersList];
    }
}

- (void)moveRight:(id)sender {
    if ([[self window] firstResponder] == foldersList) {
        [[self window] makeFirstResponder:mailboxMessageList];
    }
}


- (void)moveMessages:(NSArray*)messages toFolder:(NSString*)folder {
    
    // what about a combined view of multiple folders?  How would we handle that?
    
    [[[self undoManager] prepareWithInvocationTarget:self] moveMessages:messages toFolder:[self selectedFolderPath]];
    
    // FIXME: why isn't undo working?
    
    // this is a work in progress.
    LBAccount *currentAccount = [[appDelegate accounts] lastObject];
    
    [[currentAccount server] moveMessages:messages inFolder:[self selectedFolderPath] toFolder:folder finshedBlock:^(BOOL arg1, NSError *arg2) {
    
        NSLog(@"All done with move... I think");
    }];
    
}

- (void)delete:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    if ([[self window] firstResponder] != mailboxMessageList) {
        return;
    }
    
    LBAccount *currentAccount               = [[appDelegate accounts] lastObject];
    __block NSArray *messageList            = [[currentAccount server] messageListForPath:[self selectedFolderPath]];
    __block NSMutableArray *mesagesToDelete = [NSMutableArray array];
    
    [[mailboxMessageList selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [mesagesToDelete addObject:[messageList objectAtIndex:idx]];
    }];
    
    [self moveMessages:mesagesToDelete toFolder:LATrashFolderName];
}

- (void)replyToSelectedMessage:(id)sender {
    
    NSInteger selectedRow = [mailboxMessageList selectedRow];
    
    if (selectedRow < 0) {
        // FIXME: we should validate the menu item.
        return;
    }
    
    LBAccount *currentAccount = [[appDelegate accounts] lastObject];
    
    NSArray *messageList = [[currentAccount server] messageListForPath:[self selectedFolderPath]];
    
    LBMessage *msg = [messageList objectAtIndex:selectedRow];
    
    if (![msg messageDownloaded]) {
        // FIXME: validate for this case as well.
        return;
    }
    
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    NSError *err = nil;
    LADocument *doc = [dc openUntitledDocumentAndDisplay:YES error:&err];
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    [doc setFromList:[account fromAddress]];
    [doc setToList:[[msg sender] email]];
    
    // FIXME: - 72?  a hidden pref maybe?
    [doc setMessage:LBWrapLines(LBQuote([msg body], @">"), 72)];
    
    NSString *subject = [msg subject];
    if (![[subject lowercaseString] hasPrefix:@"re: "]) {
        subject = [NSString stringWithFormat:@"Re: ", subject];
    }
    
    [doc setSubject:subject];
    
    [doc updateChangeCount:NSChangeDone];
    
}


@end


