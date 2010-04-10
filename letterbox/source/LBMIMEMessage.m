//
//  LBMIMEMessage.m
//  LetterBox
//
//  Created by Alex Morega on 2010-04-04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LBMIMEMessage.h"
#import "LBMIMEParser.h"


@implementation LBMIMEMessage

@synthesize content;
@synthesize boundary;

+ (LBMIMEMessage*) message {
    return [[LBMIMEMessage alloc] init];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        headers  = [[NSMutableArray alloc] init];
        subparts    = [[NSMutableArray alloc] init];
    }
    boundary = nil;
    return self;
}

- (void)dealloc {
    [subparts release];
    [headers release];
    [content release];
    [boundary release];
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
    return [[subparts copy] autorelease];
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

- (NSData*)decodedData {
    NSString *cte = [self headerValueForName:@"content-transfer-encoding"];
    if ([cte isEqualToString:@"base64"]) {
        NSString* base64_data = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return LBMIMEDataByDecodingBase64String(base64_data);
    }
    else {
        return nil;
    }
}

- (BOOL)isMultipart {
    return [[[self contentType] lowercaseString] hasPrefix:@"multipart/"];
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

@end
