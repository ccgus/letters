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
    IBOutlet NSTabView     *tabView;
    
    IBOutlet NSTextField   *serverField;
    IBOutlet NSTextField   *usernameField;
    IBOutlet NSTextField   *passwordField;
    IBOutlet NSTextField   *fromAddressField;
    IBOutlet NSTextField   *portField;
    
    IBOutlet NSTextField   *smtpServerField;
    IBOutlet NSTextField   *smtpServerPortField;
    
    IBOutlet NSButton      *tlsButton;   
    
    // Import
    NSMutableArray         *mailAccounts;
    NSMutableDictionary    *smtpAccounts;
    IBOutlet NSButton      *importButton;
    IBOutlet NSTableView   *importTableView;
    IBOutlet NSSecureTextField* importPasswordField;
    
    IBOutlet NSWindow      *importPasswordWindow;
}

- (IBAction)switchToImportTab:(id)sender;
- (IBAction)createAccount:(id)sender;

- (IBAction)cancel:(id)sender;
- (IBAction)importSelectedAccount:(id)sender;

- (IBAction)cancelPassword:(id)sender;
- (IBAction)okPassword:(id)sender;
@end
