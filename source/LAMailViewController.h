//
//  LAMailViewController.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LAMailViewController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTableView *mailboxMessageList;
    IBOutlet NSTableView *foldersList;
    IBOutlet NSProgressIndicator *workingIndicator;
    IBOutlet NSTextView *messageTextView;
    
    LBServer *_server;
    NSMutableArray *_messages;
    NSMutableArray *_folders;
    
    NSString *_statusMessage;
}

@property (retain) NSMutableArray *folders;
@property (retain) LBServer *server;
@property (retain) NSString *statusMessage;


+ (id) openNewMailViewController;

- (void) connectToServerAndList;

@end
