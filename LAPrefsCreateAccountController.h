//
//  LAPrefsCreateAccountController.h
//  Letters
//
//  Created by Steven Canfield on 1/30/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LAAppDelegate.h"

@interface LAPrefsCreateAccountController : NSWindowController {
    IBOutlet NSTextField   *serverField;
    IBOutlet NSTextField   *usernameField;
    IBOutlet NSTextField   *passwordField;
    IBOutlet NSTextField   *fromAddressField;
    IBOutlet NSTextField   *portField;
    
    IBOutlet NSTextField   *smtpServerField;
    IBOutlet NSTextField   *smtpServerPortField;
    
    IBOutlet NSButton      *tlsButton;    
}

- (IBAction)importAccount:(id)sender;
- (IBAction)createAccount:(id)sender;
@end
