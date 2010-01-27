//
//  LAPrefsWindowController.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LAPrefsWindowController : NSWindowController {
    
    IBOutlet NSTextField *serverField;
    IBOutlet NSTextField *usernameField;
    IBOutlet NSTextField *passwordField;
    IBOutlet NSTextField *fromAddressField;
    IBOutlet NSTextField *portField;
    
    IBOutlet NSTextField *smtpServerField;
    IBOutlet NSTextField *smtpServerPortField;
    
    IBOutlet NSButton *tlsButton;
}

- (void)saveAccountSettings:(id)sender;
- (void)importMailAccount:(id)sender;
@end
