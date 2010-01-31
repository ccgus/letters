//
//  LAPrefsGeneralModule.m
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsAccountsModule.h"
#import "LAAppDelegate.h"
#import <LetterBox/LetterBox.h>


@interface LAPrefsAccountsModule ()
- (void) loadAccountSettings:(NSUInteger)accountIndex;
- (void) saveAccountSettings:(NSUInteger)accountIndex;
@end


#pragma mark -


@implementation LAPrefsAccountsModule

- (id)init {
    return [super initWithNibName:@"LAPrefsAccountsModule" bundle:nil];
}

- (NSString *)identifier {
    return @"LAPrefsAccountsModule";
}

- (NSString *)title {
    return NSLocalizedString (@"Accounts", @"Title for the Accounts toolbar button in the Preferences panel");
}

- (NSImage *)image {
    return [NSImage imageNamed:@"NSUser"];
}

- (void)willSelect {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:@"AccountUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newAccountCreated:) name:@"NewAccountCreated" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [createAccountController release];
    [super dealloc];
}

- (void)awakeFromNib {
    if( [[appDelegate accounts] count] == 0 ) {
        [self performSelector:@selector(addAccount:) withObject:nil afterDelay:0.1];
    }
}

// ----------------------------------------------------------------------------
#pragma mark -
#pragma mark Delegate Methods
// ----------------------------------------------------------------------------

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[appDelegate accounts] count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    LBAccount* account = [[appDelegate accounts] objectAtIndex:row];
    return [account username];
}
- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    if( [proposedSelectionIndexes count] == 0 ) {
        [deleteAccountButton setEnabled:NO];
        [accountInformationView setHidden:YES];
        [blankLabel setHidden:NO];
    } else {
        [deleteAccountButton setEnabled:YES];
        [blankLabel setHidden:YES];
        [accountInformationView setHidden:NO];
    }
    
    NSInteger existingSelectionIndex = -1;
    if( [[tableView selectedRowIndexes] count] > 0 ) {
        existingSelectionIndex = [[tableView selectedRowIndexes] firstIndex];
    }
    
    NSInteger proposedIndex = -1;
    if( [proposedSelectionIndexes count] > 0 ) {
        proposedIndex = [proposedSelectionIndexes firstIndex];
    }
    
    if( existingSelectionIndex >= 0 ) {
        [self saveAccountSettings:existingSelectionIndex];
    }
    
    if( proposedIndex >= 0 ) {
        [self loadAccountSettings:proposedIndex];
    }
    
    return proposedSelectionIndexes;
}



// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark Private Methods
// ----------------------------------------------------------------------------

- (void)loadAccountSettings:(NSUInteger)accountIndex {
    LBAccount* account = [[appDelegate accounts] objectAtIndex:accountIndex];
    
    assert(account);
    
    [serverField        setStringValue:[account imapServer] ? [account imapServer] : @""];
    [smtpServerField    setStringValue:[account smtpServer] ? [account smtpServer] : @""];
    
    [fromAddressField setStringValue:[account fromAddress] ? [account fromAddress] : @""];
    
    [usernameField setStringValue:[account username]   ? [account username] : @""];
    [passwordField setStringValue:[account password]   ? [account password] : @""];
    
    [portField           setIntValue:[account imapPort]];
    [smtpServerPortField setIntValue:25]; // TODO!
    
    [tlsButton setState:[account connectionType] == CONNECTION_TYPE_TLS ? NSOnState : NSOffState];
}

- (void)saveAccountSettings:(NSUInteger)accountIndex {
    LBAccount *account = [[appDelegate accounts] objectAtIndex:accountIndex];
    
    assert(account);
    
    [account setImapServer:[serverField stringValue]];
    [account setSmtpServer:[smtpServerField stringValue]];
    
    debug(@"[fromAddressField stringValue]: %@", [fromAddressField stringValue]);
    
    [account setFromAddress:[fromAddressField stringValue]];
    
    [account setImapPort:[portField intValue]];
    [account setUsername:[usernameField stringValue]];
    [account setPassword:[passwordField stringValue]];
    
    [account setConnectionType:[tlsButton state] ? CONNECTION_TYPE_TLS : CONNECTION_TYPE_PLAIN];
    
    // maybe there should be an updateAccount: or addAccount: or somethen'
    [appDelegate saveAccounts];
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"NewAccountCreated" object:nil];
}

- (IBAction)saveAccount:(id)sender {
    NSInteger selectedIndex = [[accountList selectedRowIndexes] firstIndex];
    [self saveAccountSettings:selectedIndex];
}

- (void)accountUpdated:(NSNotification*)note {
}

- (IBAction)addAccount:(id)sender {
    [createAccountController release];
    createAccountController = [[LAPrefsCreateAccountController alloc] initWithWindowNibName:@"CreateAccount"];    
    [NSApp beginSheet:createAccountController.window modalForWindow:[[self view] window] modalDelegate:self didEndSelector:@selector(addAccountSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)addAccountSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)newAccountCreated:(NSNotification*)note {
    [accountList reloadData];
    [accountList selectRowIndexes:[NSIndexSet indexSetWithIndex:[[appDelegate accounts] count]-1] byExtendingSelection:NO];
    [self loadAccountSettings:[[appDelegate accounts] count]-1];
}

- (IBAction)deleteAccount:(id)sender {
    NSInteger accountIndex = [accountList selectedRow];
    [appDelegate removeAccount:accountIndex];
    [appDelegate saveAccounts];
    [accountList reloadData];
}

@end
