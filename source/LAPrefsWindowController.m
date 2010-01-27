//
//  LAPrefsWindowController.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LAPrefsWindowController.h"
#import "LAAppDelegate.h"
#import "LAAccountImportController.h"
#import <LetterBox/LetterBox.h>

@interface LAPrefsWindowController ()

- (void) loadAccountSettings:(LBAccount*)account;

@end

@implementation LAPrefsWindowController

- (void)awakeFromNib {
    
    if ([[appDelegate accounts] count]) {
        [self loadAccountSettings:[[appDelegate accounts] lastObject]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:@"AccountUpdated" object:nil];
}

- (void)loadAccountSettings:(LBAccount*)account {
    
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

- (void)saveAccountSettings:(id)sender {
    
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
    
}

- (IBAction)importMailAccount:(id)sender {
    LAAccountImportController* importController = [[LAAccountImportController alloc] initWithWindowNibName:@"AccountImport"];
    [[importController window] center];
    [[importController window] makeKeyAndOrderFront:self];
}

- (void)accountUpdated:(NSNotification*)note {
    [self loadAccountSettings:[[appDelegate accounts] lastObject]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
