//
//  LBMIMEMessage.m
//  LetterBox
//
//  Created by Alex Morega on 2010-04-04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LBMIMEMessage.h"
#import "LBNSStringAdditions.h"
#include <openssl/bio.h>
#include <openssl/evp.h>


@implementation LBMIMEMessage

@synthesize content;
@synthesize subparts;
@synthesize defects;
@synthesize headers;

+ (LBMIMEMessage*) message {
    return [[[LBMIMEMessage alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        headers = [[NSMutableArray array] retain];
        subparts = [[NSMutableArray array] retain];
        defects = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc {
    [subparts release];
    [headers release];
    [defects release];
    [content release];
    [super dealloc];
}

- (void)addHeaderWithName:(NSString*)name andValue:(NSString*)value {
    [headers addObject:[NSArray arrayWithObjects:name, value, nil]];
}

- (NSString*)headerValueForName:(NSString*)name {
    name = [name lowercaseString];
    for (NSArray *h in headers) {
        if ([name isEqualToString:[[h objectAtIndex:0] lowercaseString]]) {
            return [h objectAtIndex:1];
        }
    }
    return nil;
}

- (NSString*)contentType {
    return [self headerValueForName:@"content-type"];
}

- (void)addSubpart:(LBMIMEMessage *)subpart {
    if (subpart == nil) {
        return;
    }
    [subparts addObject:subpart];
}

- (void)removeSubpart:(LBMIMEMessage*)subpart {
    if (subpart == nil) {
        return;
    }
    [subparts removeObject:subpart];
}

- (NSData*)contentTransferDecoded {
    NSString *cte = [[self headerValueForName:@"content-transfer-encoding"] lowercaseString];
    if ([cte isEqualToString:@"base64"]) {
        NSString* base64_data = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return LBMIMEDataFromBase64(base64_data);
    }
    else if ([cte isEqualToString:@"quoted-printable"]) {
        return LBMIMEDataFromQuotedPrintable(content);
    }
    else {
        return nil;
    }
}

- (BOOL)isMultipart {
    return [[[self contentType] lowercaseString] hasPrefix:@"multipart/"];
}

- (NSString*)multipartBoundary {
    return [self contentTypeAttribute:@"boundary"];
}

- (NSString*)contentTypeAttribute:(NSString*)attribName {
    // TODO: this function needs a battery of unit tests
    NSString *attribString = nil;
    NSArray *components = [[self contentType] componentsSeparatedByString:@";"];
    NSString *attribAssignment = [NSString stringWithFormat:@"%@=", attribName];
    
    for (NSString *component in components) {
        if ([[[component lowercaseString] trim] hasPrefix:attribAssignment]) {
            attribString = [component substringFromIndex:NSMaxRange([component rangeOfString:attribAssignment])];
            
            if ([attribString hasPrefix:@"\""] && [attribString hasSuffix:@"\""]) {
                attribString = [attribString substringWithRange:NSMakeRange(1, [attribString length] - 2)]; // remove the "s on either end
            }
            
            return [attribString trim];
        }
    }
    
    return nil;
}

@end

NSData* LBMIMEDataFromQuotedPrintable(NSString* value) {
    // TODO: this function needs a battery of unit tests
    NSStringEncoding enc = NSISOLatin1StringEncoding;
    value = [value stringByReplacingOccurrencesOfString:@"=\n" withString:@""];
    value = [value stringByReplacingOccurrencesOfString:@"=" withString:@"%"];
    value = [value stringByReplacingPercentEscapesUsingEncoding:enc];
    return [value dataUsingEncoding:enc];
}

NSData *LBMIMEDataFromBase64(NSString *encodedString)
{
    if ( ! [encodedString hasSuffix:@"\n"] ){
        encodedString = [encodedString stringByAppendingString:@"\n"];
    }
    NSData *encodedData = [encodedString dataUsingEncoding:NSASCIIStringEncoding];
    NSMutableData *decodedData = [NSMutableData data];
    
    char buf[512];
    uint bufLength;
    
    BIO *b64coder = BIO_new(BIO_f_base64());
    BIO *b64buffer = BIO_new_mem_buf((void *)[encodedData bytes], [encodedData length]);
    
    b64buffer = BIO_push(b64coder, b64buffer);
    
    while ( (bufLength = BIO_read(b64buffer, buf, 512)) > 0 ) {
        [decodedData appendBytes:buf length:bufLength];
    }
    BIO_free_all(b64buffer);
    
    return [[[NSData alloc] initWithData:decodedData] autorelease];
}

NSString* wrap_line(NSMutableString *line) {
    int snip_index = [line length];
    while (snip_index > 75) {
        snip_index -= 1;
        if ([line characterAtIndex:snip_index-2] == '=') {
            // the last character was an escape sequence. remove it wholesale.
            snip_index -= 2;
        }
    }
    NSString *whole_line = [line substringToIndex:snip_index];
    [line setString:[line substringFromIndex:snip_index]];
    return [whole_line stringByAppendingString:@"=\r\n"];
}

NSString* LBMIMEQuotedPrintableFromData(NSData* value) {
    NSMutableString *output = [NSMutableString stringWithCapacity:[value length]*2];
    NSMutableString *line = [NSMutableString stringWithCapacity:100];
    
    int line_size = 0;
    for (int i = 0; i < [value length]; i++) {
        unsigned char ch = ((unsigned const char *)[value bytes])[i];
        
        if (ch == '\r') {
            if (i+1 < [value length] && ((unsigned const char *)[value bytes])[i+1] == '\n') {
                // if we are at CR before a NL, skip one character ahead
                i += 1;
            }
            // but anyway, treat this as a newline
            ch = '\n';
        }
        
        if (ch == '\n') {
            unsigned char last_ch = [line characterAtIndex:[line length]-1];
            if (last_ch == ' ' || last_ch == '\t') {
                [line setString:[line substringToIndex:[line length]-1]];
                [line appendFormat:@"=%02X", last_ch];
            }
            if ([line length] > 76) {
                [output appendString:wrap_line(line)];
            }
            [output appendString:line];
            [output appendString:@"\r\n"];
            [line setString:@""];
            continue;
        }
        
        if (! (ch == ' ' || ch == '\t' || (ch >= '!' && ch <= '<') || (ch >= '>' && ch <= '~'))) {
            // need to quote
            [line appendFormat:@"=%02X", ch];
        }
        else {
            // don't quote
            [line appendFormat:@"%c", ch];
        }
        
        // make sure lines don't get too long
        if ([line length] > 76) {
            [output appendString:wrap_line(line)];
        }
    }
    
    // terminate the last line
    if ([line length] > 0) {
        if(! [line hasSuffix:@"\r\n"]) {
            if ([line length] > 75) {
                [output appendString:wrap_line(line)];
            }
            [line appendString:@"=\r\n"];
        }
        [output appendString:line];
    }
    
    return output;
}
