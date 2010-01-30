//
//  LAPrefsWindowController.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// :joachim:20100128
// This is a singleton class that provides a framework for displaying and maintaining preferences.
// It displays a prefs panel hosting a toolbar that can be expanded via plug-ins.
// NOTE: Plug-ins are not currently supported, but it easily can be.
// And when so, maybe the built-in modules should be implemented that way too.
// The implementation doesn't currently suport incremental loading of modules 
// (in case we want to support that the user can just drag/drop plug-ins without having to relaunch the app.)

// All modules must cnform to this protocol
@protocol LAPrefsModule
@required
- (NSString *)identifier;
- (NSString *)title;
- (NSImage *)image;
- (NSView *)view;
@optional
- (void)willSelect; // Is called before the module's view is being shown
@end


@interface LAPrefsNonOpaqueView : NSView {
    
}

@end

#pragma mark -


@interface LAPrefsWindowController : NSWindowController <NSToolbarDelegate> {
    
    NSMutableArray    *modules; // Currently loaded modules
    id<LAPrefsModule>  selectedModule; // The currently selected module
}

+ (LAPrefsWindowController *)sharedController;
- (void)selectModuleWithIdentifier:(NSString *)moduleId;

@end
