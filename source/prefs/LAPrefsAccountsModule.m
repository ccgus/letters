//
//  LAPrefsGeneralModule.m
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsAccountsModule.h"
#import "LAAppDelegate.h"
#import "LAAccountImportController.h"
#import <LetterBox/LetterBox.h>


@interface LAPrefsAccountsModule ()
- (void) loadAccountSettings:(LBAccount*)account;
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
	
    if ([[appDelegate accounts] count]) {
        [self loadAccountSettings:[[appDelegate accounts] lastObject]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:@"AccountUpdated" object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark Private Methods
// ----------------------------------------------------------------------------

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

@end
