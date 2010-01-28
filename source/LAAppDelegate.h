//
//  LAAppDelegate.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define appDelegate (LAAppDelegate*)[[NSApplication sharedApplication] delegate]

@interface LAAppDelegate : NSObject {
    NSMutableArray *accounts;
    NSTimer        *periodicMailCheckTimer;
}

@property (retain) NSMutableArray *mailViews;


- (void)openNewMailView:(id)sender;
- (void)openPreferences:(id)sender;
- (void)openPreferences:(id)sender selectModuleWithId:(NSString *)moduleId;
- (void)saveAccounts;

- (NSArray*) accounts;

@end
