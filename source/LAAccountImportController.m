//
//  LAAccountImportController.m
//  Letters
//
//  Created by Steven Canfield on 1/25/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAAccountImportController.h"
#import "LAAppDelegate.h"

@interface LAAccountImportController ()
- (void)loadMailAccounts;
@end



@implementation LAAccountImportController

- (id)initWithWindowNibName:(NSString *)windowNibName {
<<<<<<< HEAD
	self = [super initWithWindowNibName:windowNibName];
	if(!self) return nil;
	
	[self loadMailAccounts];
	
	return self;
}

- (void)loadMailAccounts {
	mailAccounts = [[NSMutableArray alloc] init];
=======
    
	self = [super initWithWindowNibName:windowNibName];
	if (self != nil) {
		[self loadMailAccounts];
	}
    
	return self;
}

- (void)dealloc {
    
	[_mailAccounts release];
    _mailAccounts = nil;
	
    [_smtpAccounts release];
    _smtpAccounts = nil;
	
    [super dealloc];
}

- (void)awakeFromNib {
	[tableView setDoubleAction:@selector(importSelectedAccount:)];
}


- (void)windowWillClose:(NSNotification *)notification {
    [self autorelease]; // clang is going to hate this.
}

- (void)loadMailAccounts {
	_mailAccounts = [[NSMutableArray alloc] init];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
	
	NSDictionary* mailDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.mail"];
	NSArray* imapAccounts = [mailDict objectForKey:@"MailAccounts"];
	imapAccounts = [imapAccounts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (AccountType IN %@)", [NSArray arrayWithObjects:@"LocalAccount", @"RSSAccount", @"MailCalDAVAccount", nil]]];
	
	for( NSDictionary* account in imapAccounts ) {
		NSMutableDictionary* editableAccount = [account mutableCopy];
		if( [[editableAccount objectForKey:@"AccountType"] isEqualToString:@"iToolsAccount"] ) {
			[editableAccount setObject:@"mail.mac.com" forKey:@"Hostname"];
		}
<<<<<<< HEAD
		[mailAccounts addObject:[editableAccount autorelease]];
	}
	
	smtpAccounts = [[NSMutableDictionary alloc] init];
=======
		[_mailAccounts addObject:[editableAccount autorelease]];
	}
	
	_smtpAccounts = [[NSMutableDictionary alloc] init];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
	for( NSDictionary* smtpAccount in [mailDict objectForKey:@"DeliveryAccounts"] ) {
		NSString* key = [smtpAccount objectForKey:@"Hostname"];
		if( [smtpAccount objectForKey:@"Username"] ) {
			key = [key stringByAppendingFormat:@":%@", [smtpAccount objectForKey:@"Username"]];
		}
<<<<<<< HEAD
		[smtpAccounts setObject:smtpAccount forKey:key];
=======
		[_smtpAccounts setObject:smtpAccount forKey:key];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
	}
}

- (void) importSelectedAccount:(id)sender {
	[NSApp beginSheet:passwordSheet
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(passwordSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];	
}

- (void)passwordSheetCancelPressed:(id)sender {
	[NSApp endSheet:passwordSheet returnCode:-1];
	[passwordSheet close];
}

- (void)passwordSheetOKPressed:(id)sender {
	[NSApp endSheet:passwordSheet returnCode:0];
	[passwordSheet close];
}

- (void)passwordSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if( returnCode != 0 ) { return; }
	
	NSUInteger indexOfSelectedAccount = [[tableView selectedRowIndexes] firstIndex];
<<<<<<< HEAD
	NSDictionary* mailAccount = [mailAccounts objectAtIndex:indexOfSelectedAccount];
=======
	NSDictionary* mailAccount = [_mailAccounts objectAtIndex:indexOfSelectedAccount];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
  
	LBAccount *account = [[appDelegate accounts] lastObject];
    
    assert(account);
	    
	[account setImapServer:[mailAccount objectForKey:@"Hostname"]];
	
<<<<<<< HEAD
	NSDictionary* smtpServerInfo = [smtpAccounts objectForKey:[mailAccount objectForKey:@"SMTPIdentifier"]];
=======
	NSDictionary* smtpServerInfo = [_smtpAccounts objectForKey:[mailAccount objectForKey:@"SMTPIdentifier"]];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
	[account setSmtpServer:[smtpServerInfo objectForKey:@"Hostname"]];
    	
	NSArray* addresses = [mailAccount objectForKey:@"EmailAddresses"];
	[account setFromAddress:[addresses objectAtIndex:0]];
	[account setImapPort:[[mailAccount objectForKey:@"PortNumber"] intValue]];
	
	[account setUsername:[mailAccount objectForKey:@"Username"]];
	[account setPassword:[passwordField stringValue]];
    
    [account setConnectionType:[[mailAccount objectForKey:@"SSLEnabled"] boolValue] ? CONNECTION_TYPE_TLS : CONNECTION_TYPE_PLAIN];

    // maybe there should be an updateAccount: or addAccount: or somethen'
    [appDelegate saveAccounts];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAccountCreated" object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AccountUpdated" object:nil];
	
	[[self window] close];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
<<<<<<< HEAD
	return [mailAccounts count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [[mailAccounts objectAtIndex:row] objectForKey:@"Username"];
=======
	return [_mailAccounts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [[_mailAccounts objectAtIndex:row] objectForKey:@"Username"];
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
	if( [proposedSelectionIndexes count] == 0) {
		[importButton setEnabled:NO];
<<<<<<< HEAD
	} else {
=======
	}
    else {
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
		[importButton setEnabled:YES];
	}
	return proposedSelectionIndexes;
}

<<<<<<< HEAD
- (void)dealloc {
	[mailAccounts release]; mailAccounts = nil;
	[smtpAccounts release]; smtpAccounts = nil;
	[super dealloc];
}

=======
>>>>>>> 69ba902a6f4e5a293c8dbb6a4d1a52998f80b74c
@end