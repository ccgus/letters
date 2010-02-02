//
//  With.m
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "With.h"
#import "Logging.h"


@interface NSObject (With)
- (BOOL) endWith: (NSException*)x;
@end


void _catchWith( id with, NSException *x )
{
    Warn(@"Exception thrown from WITH(%@) block: %@",[with class],x);
    if( [with respondsToSelector: @selector(endWith:)] ) {
        if( ! [with endWith: x] )
            @throw x;                           // propagate the exception if -endWith: returns NO
    } else {
        [with endWith];
    }
}



@implementation NSAutoreleasePool (With)
+ (NSAutoreleasePool*) beginWith    {return [self new];}
- (void) endWith                    {[self drain];}
- (BOOL) endWith: (NSException*)x   {[self drain]; return YES;}
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
