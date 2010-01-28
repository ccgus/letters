//
//  LAPrefsGeneralModule.m
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsGeneralModule.h"


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
}

@end
