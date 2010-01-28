//
//  LAPrefsGeneralModule.h
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsWindowController.h"


@interface LAPrefsAccountsModule : NSViewController <LAPrefsModule> {
	
    IBOutlet NSTextField   *serverField;
    IBOutlet NSTextField   *usernameField;
    IBOutlet NSTextField   *passwordField;
    IBOutlet NSTextField   *fromAddressField;
    IBOutlet NSTextField   *portField;
    
    IBOutlet NSTextField   *smtpServerField;
    IBOutlet NSTextField   *smtpServerPortField;
    
    IBOutlet NSButton      *tlsButton;
}

- (IBAction)saveAccountSettings:(id)sender;
- (IBAction)importMailAccount:(id)sender;

@end
