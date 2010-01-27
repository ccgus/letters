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
    self = [super initWithWindowNibName:windowNibName];
    if (self != nil) {
        [self loadMailAccounts];
    }
    
    return self;
}

- (void)dealloc {
    
    [mailAccounts release];
    mailAccounts = nil;
    
    [smtpAccounts release];
    smtpAccounts = nil;
    
    [super dealloc];
}

- (void)awakeFromNib {
    [tableView setDoubleAction:@selector(importSelectedAccount:)];
}


- (void)windowWillClose:(NSNotification *)notification {
    [self autorelease]; // clang is going to hate this.
}

- (void)loadMailAccounts {
    mailAccounts = [[NSMutableArray alloc] init];  
    NSDictionary* mailDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.mail"];
    NSArray* imapAccounts = [mailDict objectForKey:@"MailAccounts"];
    imapAccounts = [imapAccounts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (AccountType IN %@)", [NSArray arrayWithObjects:@"LocalAccount", @"RSSAccount", @"MailCalDAVAccount", nil]]];
    
    for (NSDictionary* account in imapAccounts) {
        NSMutableDictionary* editableAccount = [account mutableCopy];
        if ([[editableAccount objectForKey:@"AccountType"] isEqualToString:@"iToolsAccount"]) {
            [editableAccount setObject:@"mail.mac.com" forKey:@"Hostname"];
        }
        [mailAccounts addObject:[editableAccount autorelease]];
    }
    
    smtpAccounts = [[NSMutableDictionary alloc] init];
    for (NSDictionary* smtpAccount in [mailDict objectForKey:@"DeliveryAccounts"]) {
        NSString* key = [smtpAccount objectForKey:@"Hostname"];
        if ([smtpAccount objectForKey:@"Username"]) {
            key = [key stringByAppendingFormat:@":%@", [smtpAccount objectForKey:@"Username"]];
        }
        [smtpAccounts setObject:smtpAccount forKey:key];
    }
}

- (void)importSelectedAccount:(id)sender {
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
    if (returnCode != 0) { return; }
    
    NSUInteger indexOfSelectedAccount = [[tableView selectedRowIndexes] firstIndex];
    NSDictionary* mailAccount = [mailAccounts objectAtIndex:indexOfSelectedAccount];
  
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    assert(account);
        
    [account setImapServer:[mailAccount objectForKey:@"Hostname"]];
    
    NSDictionary* smtpServerInfo = [smtpAccounts objectForKey:[mailAccount objectForKey:@"SMTPIdentifier"]];
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
    return [mailAccounts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [[mailAccounts objectAtIndex:row] objectForKey:@"Username"];
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    if( [proposedSelectionIndexes count] == 0) {
        [importButton setEnabled:NO];
    }
    else {
        [importButton setEnabled:YES];
    }
    return proposedSelectionIndexes;
}
@end