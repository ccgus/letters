//
//  LBNSDataAdditions.m
//  LetterBox
//
//  Created by August Mueller on 2/21/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBNSDataAdditions.h"

#define CRLF "\r\n"

@implementation NSData (LetterBoxAdditions)

- (NSString*)lbSingleLineResponse {
    
    // *something* + crlf
    if ([self length] < 4) {
        return nil; 
    }
    
    const char *c = [self bytes];
    
    // check for completion of command.
    if (strncmp(&(c[[self length] - 2]), CRLF, 2)) {
        return nil;
    }
    
    // er... what about this char set?
    return [[[NSString alloc] initWithBytes:[self bytes] length:[self length] - 2 encoding:NSUTF8StringEncoding] autorelease];
}


- (BOOL)lbEndIsEqualTo:(NSString*)string; {
    
    if ([self length] < ([string length])) {
        return NO; 
    }
    
    const char *c = [self bytes];
    
    // check for completion of command.
    if (strncmp(&(c[[self length] - [string length]]), [string UTF8String], [string length])) {
        return NO;
    }
    
    return YES;
}

- (NSString*)lbLastLineOfMultiline {
    
    if ([self length] < 3) { // something + crlf
        return nil; 
    }
    
    NSUInteger len    = [self length];
    char *cdata       = (char *)[self bytes];
    NSUInteger idx    = len - 3;
    char *pos         = &cdata[idx];
    
    // if it doesn't end with crlf, it's bad.
    if (!(cdata[len - 1] == '\n' && cdata[len - 2] == '\r')) {
        return nil;
    }
    
    while (idx > 0) {
        // let's go backwards!
        
        if (*pos == '\n') {
            // get rid of the encountered lf, and the ending crlf
            NSRange r = NSMakeRange(idx + 1, len - (idx + 3));
            NSData *subData = [self subdataWithRange:r];
            NSString *junk = [[[NSString alloc] initWithBytes:[subData bytes] length:[subData length] encoding:NSUTF8StringEncoding] autorelease];
            return junk;
        }
        
        pos--;
        idx--;
    }
    
    return nil;
}

- (NSString*)lbFirstLine {
    
    if ([self length] < 3) { // something + crlf
        return nil; 
    }
    
    NSUInteger len    = [self length];
    NSUInteger idx    = 0;
    char *cdata       = (char *)[self bytes];
    
    while (idx < len) {
        
        if (cdata[idx] == '\r') {
            // get rid of the encountered lf, and the ending crlf
            NSRange r = NSMakeRange(0, idx);
            NSData *subData = [self subdataWithRange:r];
            NSString *junk = [[[NSString alloc] initWithBytes:[subData bytes] length:[subData length] encoding:NSUTF8StringEncoding] autorelease];
            return junk;
        }
        
        idx++;
    }
    
    return nil;
}

- (NSString*)utf8String {
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}


@end

