//
//  URLUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 4/28/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "URLUtils.h"


@implementation NSURL (MYUtilities)

+ (NSString*) my_stringByTrimmingURLString: (NSString*)string
{
    NSMutableString *trimmed = [[string mutableCopy] autorelease];
    NSRange r;
    // Remove all whitespace and newlines:
    while(YES){
        r = [trimmed rangeOfCharacterFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if( r.length==0 )
            break;
        [trimmed replaceCharactersInRange: r withString: @""];
    }
    
    // Delete surrounding "<...>":
    r = NSMakeRange(0,trimmed.length);
    if( [trimmed hasPrefix: @"<"] ) {
        r.location++;
        r.length--;
    }
    if( [trimmed hasSuffix: @">"] )
        r.length--;
    return [trimmed substringWithRange: r];
}

+ (NSURL*) my_URLWithLenientString: (NSString*)string 
                     defaultScheme: (NSString*)defaultScheme
                    allowedSchemes: (NSArray*)allowedSchemes
{
    // Trim it:
    string = [self my_stringByTrimmingURLString: string];
    if( string.length==0 )
        return nil;
    NSURL *url = [NSURL URLWithString: string];
    if( ! url )
        return nil;
    // Apply default scheme (if any):
    NSString *scheme = url.scheme.lowercaseString;
    if( scheme == nil ) {
        if(  ! defaultScheme )
            return nil;
        string = $sprintf(@"%@://%@", defaultScheme,string);
        url = [NSURL URLWithString: string];
        scheme = [url scheme];
        if( scheme == nil )
            return nil;
    }
    // Check that scheme is allowed:
    if( allowedSchemes && ![allowedSchemes containsObject: scheme] )
        return nil;
    return url;
}

@end




@implementation NSHTTPURLResponse (MYUtilities)


- (NSError*) HTTPError
{
    // HTTP status >= 300 is considered an error:
    int status = self.statusCode;
    if( status >= 300 ) {
        NSString *reason = [NSHTTPURLResponse localizedStringForStatusCode: status];
        NSDictionary *info = $dict({NSLocalizedFailureReasonErrorKey,reason});
        return [NSError errorWithDomain: MyHTTPErrorDomain code: status userInfo: info];
    } else
        return nil;
}


NSString* const MyHTTPErrorDomain = @"HTTP";


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
