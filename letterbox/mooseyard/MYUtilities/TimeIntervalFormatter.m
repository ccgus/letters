//
//  TimeIntervalFormatter.m
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "TimeIntervalFormatter.h"


@implementation TimeIntervalFormatter


- (id) init
{
    self = [super init];
    if (self != nil) {
        _showsMinutes = YES;
    }
    return self;
}

- (void) awakeFromNib
{
    _showsMinutes = YES;
}

- (void) setShowsMinutes: (BOOL)show                {_showsMinutes = show;}
- (void) setShowsFractionalSeconds: (BOOL)show      {_showsFractionalSeconds = show;}

+ (NSString*) formatTimeInterval: (NSTimeInterval)interval
{
    TimeIntervalFormatter *fmt = [[self alloc] init];
    NSString *result = [fmt stringForObjectValue: [NSNumber numberWithDouble: interval]];
    [fmt release];
    return result;
}


- (NSString*) stringForObjectValue: (id)object
{
    if (![object isKindOfClass:[NSNumber class]])
        return nil;
    NSTimeInterval time = [object doubleValue];
    NSString *sign;
    if( time==0.0 )
        return nil;
    else if( time < 0.0 ) {
        sign = @"-";
        time = -time;
    } else
        sign = @"";
    if( ! _showsFractionalSeconds )
        time = floor(time);
    int minutes = (int)floor(time / 60.0);
    if( _showsMinutes || minutes>0 ) {
        double seconds = time - 60.0*minutes;
        return [NSString stringWithFormat: (_showsFractionalSeconds ?@"%@%d:%06.3lf" :@"%@%d:%02.0lf"),
                                           sign,minutes,seconds];
    } else {
        return [NSString stringWithFormat: (_showsFractionalSeconds ?@"%@%.3lf" :@"%@%.0lf"),
                                           sign,time];
    }
}


- (BOOL)getObjectValue:(id *)anObject
             forString:(NSString *)string 
      errorDescription:(NSString **)error
{
    NSScanner *scanner = [NSScanner scannerWithString: string];
    [scanner setCharactersToBeSkipped: [NSCharacterSet whitespaceCharacterSet]];
    double seconds;
    if( [scanner isAtEnd] ) {
        seconds = 0.0;
    } else {
        if( ! [scanner scanDouble: &seconds] || seconds<0.0 ) goto error;
        if( [scanner scanString: @":" intoString: NULL] ) {
            double minutes = seconds;
            if( ! [scanner scanDouble: &seconds] || seconds<0.0 ) goto error;
            seconds += 60*minutes;
        }
        if( ! [scanner isAtEnd] ) goto error;
    }
    *anObject = [NSNumber numberWithDouble: seconds];
    return YES;
    
error:
    *anObject = nil;
    if( error )
        *error = @"Not a valid time interval";
    return NO;
}


- (BOOL)isPartialStringValid:(NSString **)partialStringPtr 
       proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
              originalString:(NSString *)origString 
       originalSelectedRange:(NSRange)origSelRange 
            errorDescription:(NSString **)error
{
    static NSCharacterSet *sIllegalChars;
    if( ! sIllegalChars )
        sIllegalChars = [[[NSCharacterSet characterSetWithCharactersInString: @"0123456789.:"] 
                                invertedSet] retain];
    return [*partialStringPtr rangeOfCharacterFromSet: sIllegalChars].length == 0;
}


@end


/*
 Copyright (c) 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
