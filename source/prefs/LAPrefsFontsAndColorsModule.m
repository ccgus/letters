//
//  LAPrefsFontsAndColorsModule.m
//  Letters
//
//  Created by Joachim Bondo on 10-01-28.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAPrefsFontsAndColorsModule.h"


@implementation LAPrefsFontsAndColorsModule

- (id)init {
    return [super initWithNibName:@"LAPrefsFontsAndColorsModule" bundle:nil];
}

- (NSString *)identifier {
    return @"LAPrefsFontsAndColorsModule";
}

- (NSString *)title {
    return NSLocalizedString (@"Fonts & Colors", @"Title for the Fonts & Color toolbar button in the Preferences panel");
}

- (NSImage *)image {
    return [NSImage imageNamed:@"NSFontPanel"];
}

/*
- (void)willSelect {
    // 
}
 */

@end
