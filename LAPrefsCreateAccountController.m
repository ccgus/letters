//
//  LAPrefsCreateAccountController.m
//  Letters
//
//  Created by Steven Canfield on 1/30/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsCreateAccountController.h"


@implementation LAPrefsCreateAccountController

- (IBAction)importAccount:(id)sender {
    [NSApp endSheet:[self window]];
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
@end
