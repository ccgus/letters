//
//  LAPrefsWindowController.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
    LAPrefsPaneTabIdUnknown = 0,
    LAPrefsPaneTabIdGeneral,
    LAPrefsPaneTabIdAccounts,
    LAPrefsPaneTabIdFontsAndColors
} LAPrefsPaneTabId;


@interface LAPrefsWindowController : NSWindowController {
    
    IBOutlet NSTabView     *tabView;
    LAPrefsPaneTabId        preSelectTabId;
    
    // General
    IBOutlet NSPopUpButton *emailAppsPopup;
    
    // Account(s)
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

- (void)selectTabWithId:(LAPrefsPaneTabId)tabId;
@end
