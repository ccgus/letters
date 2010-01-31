//
//  LAPrefsGeneralModule.h
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsWindowController.h"
#import "LAPrefsCreateAccountController.h"

@interface LAPrefsAccountsModule : NSViewController <LAPrefsModule, NSTableViewDataSource> {    
    IBOutlet NSTableView   *accountList;
    
    IBOutlet NSTextField   *serverField;
    IBOutlet NSTextField   *usernameField;
    IBOutlet NSTextField   *passwordField;
    IBOutlet NSTextField   *fromAddressField;
    IBOutlet NSTextField   *portField;
    
    IBOutlet NSTextField   *smtpServerField;
    IBOutlet NSTextField   *smtpServerPortField;
    
    IBOutlet NSButton      *tlsButton;
    
    IBOutlet NSButton      *addAccountButton;
    IBOutlet NSButton      *deleteAccountButton;
    
    IBOutlet NSView        *accountInformationView;
    IBOutlet NSTextField   *blankLabel;
    
    LAPrefsCreateAccountController* createAccountController;    
}
- (IBAction)saveAccount:(id)sender;
- (IBAction)addAccount:(id)sender;
- (IBAction)deleteAccount:(id)sender;    
@end