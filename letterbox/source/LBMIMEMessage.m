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
@synthesize defects;

+ (LBMIMEMessage*) message {
    return [[LBMIMEMessage alloc] init];
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
    for (NSArray *h in headers)
        if ([name isEqualToString:[[h objectAtIndex:0] lowercaseString]])
            return [h objectAtIndex:1];
    return nil;
}

- (NSString*)contentType {
    return [self headerValueForName:@"content-type"];
}

- (LBMIMEMessage*)superpart {
    return superpart;
}

- (NSArray*)subparts {
    return subparts;
}

- (void)addSubpart:(LBMIMEMessage *)subpart {
    if (subpart == nil) {
        return;
    }
    
    subpart->superpart = self;
    [subparts addObject:subpart];
}

- (void)removeSubpart:(LBMIMEMessage*)subpart {
    if (subpart == nil) {
        return;
    }
    
    subpart->superpart = nil;
    [subparts removeObject: subpart];
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

- (NSArray*) types {
    NSMutableArray *types = [NSMutableArray array];
    for (LBMIMEMessage *part in self.subparts) {
        if ([part contentType]) {
            [types addObject: part.contentType];
        }
    }
    
    return types;
}

- (NSString *)availableTypeFromArray:(NSArray *)types {
    NSArray *availableTypes = [self types];
    for (NSString *type in types) {
        if ([availableTypes containsObject: type]) {
            return type;
        }
    }
    
    return nil;
}

- (LBMIMEMessage*)availablePartForTypeFromArray:(NSArray*)types {
    
    for (NSString *type in types) {
        LBMIMEMessage *part = [self partForType:type];
        if (part) {
            return part;
        }
    }
    
    return nil;
}

- (LBMIMEMessage*)partForType:(NSString*)mimeType {
    
    if ([[self contentType] hasPrefix:mimeType]) {
        return self;
    }
    
    if ([self isMultipart]) {
        for (LBMIMEMessage *part in self.subparts) {
            if ([[part contentType] hasPrefix:mimeType]) {
                return part;
            }
        }
    }
    
    return nil;
}

// the MIME spec says the alternative parts are ordered from least faithful to the most faithful. we can only presume the sender has done that correctly. consider this a guess rather than being definitive.
- (NSString*)mostFailthfulAlternativeType {
    return [[self.subparts lastObject] contentType];
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
