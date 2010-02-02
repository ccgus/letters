//
//  TimeIntervalFormatter.h
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TimeIntervalFormatter : NSFormatter
{
    BOOL _showsMinutes, _showsFractionalSeconds;
}

- (void) setShowsMinutes: (BOOL)showsMinutes;
- (void) setShowsFractionalSeconds: (BOOL)showsFractionalSeconds;

+ (NSString*) formatTimeInterval: (NSTimeInterval)interval;

@end
