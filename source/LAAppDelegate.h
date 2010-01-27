//
//  LAAppDelegate.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LAPrefsWindowController.h"

#define appDelegate (LAAppDelegate*)[[NSApplication sharedApplication] delegate]

@interface LAAppDelegate : NSObject {
    
    NSMutableArray *accounts;
    
    LAPrefsWindowController *prefsWindowController;
    
    NSTimer *periodicMailCheckTimer;
}

@property (retain) NSMutableArray *mailViews;


- (void)openNewMailView:(id)sender;
- (void)openPreferences:(id)sender;
- (void)saveAccounts;

- (NSArray*) accounts;

@end
