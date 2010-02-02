//
//  MYWindowUtils.m
//  Murky
//
//  Created by Jens Alfke on 5/5/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYWindowUtils.h"


@implementation NSWindow (MYUtilities)


- (void) my_setTitleBarIcon: (NSImage*)icon
{
    NSURL *url = nil;
    if( icon ) {
        icon = [[icon copy] autorelease];
        [icon setSize: NSMakeSize(16,16)];
        url = [NSURL fileURLWithPath: @"/System/XXX"];
    }
    [self setRepresentedURL: url];
    [[self standardWindowButton:NSWindowDocumentIconButton] setImage: icon];
}

@end
