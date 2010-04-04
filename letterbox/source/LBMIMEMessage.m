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

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqual: @"properties"] ) {
        return [NSSet setWithObjects: @"contentType", @"contentID", @"contentTransferEncoding", @"contentDisposition", nil];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

+ (LBMIMEMessage*) message {
    return [[LBMIMEMessage alloc] init];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        properties  = [[NSMutableDictionary alloc] init];
        subparts    = [[NSMutableArray alloc] init];
    }
    boundary = nil;
    return self;
}

- (void)dealloc {
    [subparts release];
    [properties release];
    [content release];
    [boundary release];
    [super dealloc];
}

- (LBMIMEMessage*)superpart {
    return superpart;
}

- (NSArray*)subparts {
    return [[subparts copy] autorelease];
}

- (NSDictionary*)properties {
    return [[properties copy] autorelease];
}

- (void)setProperties:(NSDictionary *)newProperties {
    NSMutableDictionary *tmp = [newProperties mutableCopy];
    [properties release];
    properties = tmp;
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

- (NSString*)contentType {
    return [properties objectForKey:@"content-type"];
}

- (void)setContentType:(NSString*)type {
    
    if (type) {
        [properties setObject:type forKey:@"content-type"];
    }
    else {
        [properties removeObjectForKey:@"content-type"];
    }
}

- (NSString*)contentID {
    return [properties objectForKey: @"content-id"];
}

- (void)setContentID:(NSString*)type {
    
    if (type) {
        [properties setObject:type forKey:@"content-id"];
    }
    else {
        [properties removeObjectForKey:@"content-id"];
    }
}

- (NSString*)contentDisposition {
    return [properties objectForKey: @"content-disposition"];
}

- (void)setContentDisposition:(NSString*)type {
    if (type) {
        [properties setObject:type forKey:@"content-disposition"];
    }
    else {
        [properties removeObjectForKey:@"content-disposition"];
    }
}

- (NSString*)contentTransferEncoding {
    return [properties objectForKey:@"content-transfer-encoding"];
}

- (void)setContentTransferEncoding:(NSString*)type {
    if (type) {
        [properties setObject:type forKey:@"content-transfer-encoding"];
    }
    else {
        [properties removeObjectForKey:@"content-transfer-encoding"];
    }
}

- (NSData*)decodedData {
    if ([self.contentTransferEncoding isEqualToString:@"base64"]) {
        NSString* base64_data = [content stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        return LBMIMEDataByDecodingBase64String(base64_data);
    }
    else {
        return nil;
    }
}

- (BOOL)isMultipart {
    return [[self.contentType lowercaseString] hasPrefix:@"multipart/"];
}

- (NSArray*) types {
    NSMutableArray *types = [NSMutableArray array];
    for (LBMIMEMessage *part in self.subparts) {
        if (part.contentType) {
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
    
    if ([self.contentType hasPrefix:mimeType]) {
        return self;
    }
    
    if ([self isMultipart]) {
        for (LBMIMEMessage *part in self.subparts) {
            if ([part.contentType hasPrefix:mimeType]) {
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
