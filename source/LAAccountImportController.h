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
	NSMutableArray*		  mailAccounts;
	NSMutableDictionary*  smtpAccounts;
	
	IBOutlet NSButton* importButton;
	IBOutlet NSWindow* passwordSheet;
	IBOutlet NSSecureTextField* passwordField;
}
- (void) importSelectedAccount:(id)sender;

- (void)passwordSheetCancelPressed:(id)sender;
- (void)passwordSheetOKPressed:(id)sender;	
@end
