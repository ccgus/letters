//
//  LAPrefsGeneralModule.m
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsGeneralModule.h"


@interface LAPrefsGeneralModule ()
- (void)setupEmailAppsPopup;
- (void)didSelectEmailApp:(id)sender;
@end


#pragma mark -


@implementation LAPrefsGeneralModule

- (id)init {
    return [super initWithNibName:@"LAPrefsGeneralModule" bundle:nil];
}

- (NSString *)identifier {
    return @"LAPrefsGeneralModule";
}

- (NSString *)title {
    return NSLocalizedString (@"General", @"Title for the General toolbar button in the Preferences panel");
}

- (NSImage *)image {
    return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

- (void)willSelect {
    
    // Load the popup menu with email-capable apps and select the preferred email client.
    [self setupEmailAppsPopup];
}


// ----------------------------------------------------------------------------
   #pragma mark -
   #pragma mark Private Methods
// ----------------------------------------------------------------------------

- (void)setupEmailAppsPopup {
    
    // Collect information about installed email handlers
    CFStringRef mailtoScheme = CFSTR ("mailto");
    NSArray *appIds = (NSArray *)LSCopyAllHandlersForURLScheme (mailtoScheme);
    NSString *emailAppId = (NSString *)LSCopyDefaultHandlerForURLScheme (mailtoScheme);
    
    // Build the menu for the popup
    NSMenu *menu = [[NSMenu alloc] init];
    [menu setAutoenablesItems:NO];
    
    for (NSString *appId in appIds) {
        
        CFStringRef appNameRef;
        CFURLRef    appURLRef = (CFURLRef)[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:appId];
        LSCopyDisplayNameForURL (appURLRef, &appNameRef);
        
        // FIXME : jasonrm - This might not be the best place to check this.
        if ( appURLRef != NULL ) {
            // Get the 16 x 16 app icon
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[(NSURL *)appURLRef path]];
            [icon setSize:NSMakeSize (16, 16)];

            // Make the menu item
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:(NSString *)appNameRef action:@selector (didSelectEmailApp:) keyEquivalent:@""];
            [item setTarget:self];
            [item setImage:icon];
            [item setRepresentedObject:appId];
            [item setState:([appId isEqualToString:emailAppId] ? NSOnState : NSOffState)];

            [menu addItem:item];
            CFRelease (appNameRef);
            [item release];
        }
    }
    
    [emailAppsPopup setMenu:menu];
    
    // Make sure the popup can contain the content within the frame of the panel.
    // The popup currently takes up the maximum width (because of its IB autosizing).
    NSRect maxFrame = [emailAppsPopup frame];
    [emailAppsPopup sizeToFit];
    if ([emailAppsPopup bounds].size.width > maxFrame.size.width) {
        // Popup is now too wide after autosizing, revert to max width
        [emailAppsPopup setFrame:maxFrame];
    }
    
    // Clean up
    [menu release];
    [emailAppId release];
    [appIds release];
}

- (void)didSelectEmailApp:(id)sender {
    // User chose an app from the popup menu, register the email handler with Launch Services.
    LSSetDefaultHandlerForURLScheme (CFSTR ("mailto"), (CFStringRef)[sender representedObject]);
}

@end
