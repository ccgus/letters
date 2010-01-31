//
//  LAPrefsCreateAccountController.m
//  Letters
//
//  Created by Steven Canfield on 1/30/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsCreateAccountController.h"

@interface LAPrefsCreateAccountController ()
- (void)loadMailAccounts;
@end


@implementation LAPrefsCreateAccountController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if(!self) return nil;
    [self loadMailAccounts];
    return self;
}

- (void)awakeFromNib {
    [importTableView setDoubleAction:@selector(importSelectedAccount:)];
}

- (IBAction)switchToImportTab:(id)sender {
    [tabView selectTabViewItemAtIndex:1];
}

- (IBAction)createAccount:(id)sender {
    [appDelegate addAccount];
    LBAccount *account = [[appDelegate accounts] lastObject];
    
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewAccountCreated" object:nil];
    [NSApp endSheet:[self window]];
}

- (IBAction)cancel:(id)sender {
    [NSApp endSheet:[self window]];
}

- (IBAction)importSelectedAccount:(id)sender {
    [NSApp runModalForWindow:importPasswordWindow];
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

- (IBAction)cancelPassword:(id)sender {
    [NSApp stopModalWithCode:1];
    [importPasswordWindow orderOut:self];
}

- (IBAction)okPassword:(id)sender {
    [NSApp stopModalWithCode:0];
    [importPasswordWindow orderOut:self];
    
    NSUInteger indexOfSelectedAccount = [[importTableView selectedRowIndexes] firstIndex];
    NSDictionary* mailAccount = [mailAccounts objectAtIndex:indexOfSelectedAccount];
    
    [appDelegate addAccount];
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    assert(account);
    
    [account setImapServer:[mailAccount objectForKey:@"Hostname"]];
    
    NSDictionary* smtpServerInfo = [smtpAccounts objectForKey:[mailAccount objectForKey:@"SMTPIdentifier"]];
    [account setSmtpServer:[smtpServerInfo objectForKey:@"Hostname"]];
    
    NSArray* addresses = [mailAccount objectForKey:@"EmailAddresses"];
    [account setFromAddress:[addresses objectAtIndex:0]];
    [account setImapPort:[[mailAccount objectForKey:@"PortNumber"] intValue]];
    
    [account setUsername:[mailAccount objectForKey:@"Username"]];
    [account setPassword:[importPasswordField stringValue]];
    
    [account setConnectionType:[[mailAccount objectForKey:@"SSLEnabled"] boolValue] ? CONNECTION_TYPE_TLS : CONNECTION_TYPE_PLAIN];
    
    // maybe there should be an updateAccount: or addAccount: or somethen'
    [appDelegate saveAccounts];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewAccountCreated" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountUpdated" object:nil];
 
    [NSApp endSheet:[self window]];
}
@end
