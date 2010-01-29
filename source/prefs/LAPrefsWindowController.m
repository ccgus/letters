//
//  LAPrefsWindowController.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LAPrefsWindowController.h"
#import "LAPrefsGeneralModule.h"
#import "LAPrefsAccountsModule.h"
#import "LAPrefsFontsAndColorsModule.h"


// The prefs panel will only resize vertically, no ugly horizontal resizing, thank you.
#define LA_PREFS_WINDOW_WIDTH 520

LAPrefsWindowController *singleton = nil;

@interface LAPrefsWindowController ()
- (id<LAPrefsModule>)moduleForIdentifier:(NSString *)moduleId;
- (void)selectToolbarItem:(NSToolbarItem *)sender;
- (void)selectModule:(id<LAPrefsModule>)module;
- (void)loadModules;
- (void)setupToolbar;
- (void)updateToolbar;
@end


#pragma mark -


@implementation LAPrefsWindowController

+ (LAPrefsWindowController *)sharedController {
    if (!singleton) {
        singleton = [[self alloc] init];
    }
    return singleton;
}

- (id)init {
    // The creation of the panel is so minimal that I won't bother using a xib for it.
    // The window height will be adjusted when loading the relevant prefs module.
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect (0, 0, LA_PREFS_WINDOW_WIDTH, 120) 
                                                styleMask:NSTitledWindowMask | NSClosableWindowMask 
                                                  backing:NSBackingStoreBuffered
                                                    defer:YES];
    [panel setShowsToolbarButton:NO];
    [self setWindow:panel];
    
    [self loadModules];
    [self setupToolbar];
    
    return self;
}

- (void)showWindow:(id)sender {
    
    // Restore previously selected module from earlier app session.
    [self selectModuleWithIdentifier:[LAPrefs objectForKey:@"LAPrefsWindowSelectedModule"]];
    
    [[self window] center];
    [super showWindow:sender];
}

- (void)dealloc {
    [modules release], modules = nil;
    [super dealloc];
}

//- (NSString *)windowFrameAutosaveName {
//    return @"LAPrefsWindowController";
//}


// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark Toolbar Item Selection
// ----------------------------------------------------------------------------

- (void)selectToolbarItem:(NSToolbarItem *)sender {
    // User pressed a toolbar item, select it
    [self selectModuleWithIdentifier:[sender itemIdentifier]];
}

- (void)selectModuleWithIdentifier:(NSString *)moduleId {
    [self selectModule:[self moduleForIdentifier:moduleId]];
}

- (void)selectModule:(id<LAPrefsModule>)module {
    
    if (!module) {
        module = [modules objectAtIndex:0];
    }
    
    if (module == selectedModule) {
        return;
    }
    
    // Remove current view
    [[selectedModule view] removeFromSuperview];
    
    NSView   *view   = [module view];
    NSWindow *window = [self window];
    
    // Adjust panel height
    NSRect frame = [window frame];
    NSRect contentFrame = [window contentRectForFrameRect:frame];
    CGFloat deltaHeight = NSHeight ([view bounds]) - contentFrame.size.height;
    frame.origin.y -= deltaHeight;
    frame.size.height += deltaHeight;
    [window setFrame:frame display:YES animate:YES];
    
    [[window toolbar] setSelectedItemIdentifier:[module identifier]];
    [window setTitle:[module title]];
    
    // Show the new view, make sure it stretches horizontally to fill the prefs pane
    frame = [view bounds];
    frame.size.width = LA_PREFS_WINDOW_WIDTH;
    [view setFrame:frame];
    [[window contentView] addSubview:view];
    
    // Give the module a chance to lazy-load its stuff
    if ([(NSObject *)module respondsToSelector:@selector (willSelect)]) {
        [module willSelect];
    }
    
    // Persist selection
    [LAPrefs setObject:[module identifier] forKey:@"LAPrefsWindowSelectedModule"];
    
    selectedModule = module;
}


// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark NSToolbarDelegate Protocol
// ----------------------------------------------------------------------------

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    // Return the identifiers of the loaded modules
    NSMutableArray *identifiers = [NSMutableArray array];
    for (id<LAPrefsModule>module in modules) {
        [identifiers addObject:[module identifier]];
    }
    return identifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    // They're all selectable
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return nil; // Since the toolbar can't be customized
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    // Create an NSToolbarItem that corresponds to the module with the given id.
    id<LAPrefsModule> module = [self moduleForIdentifier:itemIdentifier];
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    if (!module) {
        return item;
    }
    
    // Configure the toolbar item
    [item setLabel:[module title]];
    [item setImage:[module image]];
    [item setTarget:self];
    [item setAction:@selector (selectToolbarItem:)];
    
    return item;
}


// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark Private Methods
// ----------------------------------------------------------------------------

- (id<LAPrefsModule>)moduleForIdentifier:(NSString *)moduleId {
    for (id<LAPrefsModule>module in modules) {
        if ([[module identifier] isEqualToString:moduleId]) {
            return module;
        }
    }
    return nil;
}

- (void)loadModules {
    // Loads built-in and external prefs modules.
    
    [modules release];
    modules = [[NSMutableArray alloc] initWithCapacity:8];
    
    // Add built-in modules
    id<LAPrefsModule> module = [[LAPrefsGeneralModule alloc] init]; // General
    [modules addObject:module];
    [(id)module release];
    module = [[LAPrefsAccountsModule alloc] init]; // Accounts
    [modules addObject:module];
    [(id)module release];
    module = [[LAPrefsFontsAndColorsModule alloc] init]; // Fonts & Colots
    [modules addObject:module];
    [(id)module release];
    
    // Add external modules - currently not supported
    
}

- (void)setupToolbar {
    // Sets up the toolbar with both built-in and plugin modules.
    
    NSToolbar *toolbar = [[self window] toolbar];
    if (!toolbar) {
        toolbar = [[[NSToolbar alloc] initWithIdentifier:@"LAPrefsToolbar"] autorelease];
    }
    
    // Configure for a preference panel
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
    
    [self updateToolbar];
}

- (void)updateToolbar
{
    // For now, just add all module items. If drag/drop plug-in installation needs to be supported, alter existing toolbar by removing and adding individual items
    NSToolbar *toolbar = [[self window] toolbar];
    for (NSInteger i = 0; i < [modules count]; i++) {
        [toolbar insertItemWithItemIdentifier:[(id<LAPrefsModule>)[modules objectAtIndex:i] identifier] atIndex:i];
    }
}

@end
