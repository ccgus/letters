//
//  DateUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 3/25/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "DateUtils.h"

#include <assert.h>
#include <CoreServices/CoreServices.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>


/** Absolute time (since 'reference date') to NSDate. 0.0 -> nil. */
NSDate* $date( CFAbsoluteTime time )
{
    CAssert(time>=0.0 && time < 1.0e15, @"Bogus timestamp %g",time);
    return time ?[NSDate dateWithTimeIntervalSinceReferenceDate: time] :nil;
}


/** NSDate to absolute time (since 'reference date'). nil -> 0.0 */
CFAbsoluteTime $time( NSDate* date )
{
    return date ?[date timeIntervalSinceReferenceDate] :0.0;
}



NSTimeInterval TimeIntervalSinceBoot(void)
{
    // Adapted from http://developer.apple.com/qa/qa2004/qa1398.html
    // Have to do some union tricks because AbsoluteToNanoseconds
    // works in terms of UnsignedWide, which is a structure rather
    // than a proper 64-bit integer.
    union {
        uint64_t asUInt64;
        UnsignedWide asUWide;
    } t;
    t.asUInt64 = mach_absolute_time();
    t.asUWide = AbsoluteToNanoseconds(t.asUWide);
    return t.asUInt64 / 1.0e9;
}



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
