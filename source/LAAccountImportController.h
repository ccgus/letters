//
//  LAAccountImportController.h
//  Letters
//
//  Created by Steven Canfield on 1/25/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LAAccountImportController : NSWindowController<NSTableViewDelegate,NSTableViewDataSource> {
	IBOutlet NSTableView *tableView;
<<<<<<< HEAD
	NSMutableArray*		  mailAccounts;
	NSMutableDictionary*  smtpAccounts;
	
	IBOutlet NSButton* importButton;
	IBOutlet NSWindow* passwordSheet;
	IBOutlet NSSecureTextField* passwordField;
=======
	IBOutlet NSButton* importButton;
	IBOutlet NSWindow* passwordSheet;
	IBOutlet NSSecureTextField* passwordField;
    
    
	NSMutableArray*		  _mailAccounts;
	NSMutableDictionary*  _smtpAccounts;
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
}
- (void) importSelectedAccount:(id)sender;

- (void)passwordSheetCancelPressed:(id)sender;
- (void)passwordSheetOKPressed:(id)sender;	
@end
