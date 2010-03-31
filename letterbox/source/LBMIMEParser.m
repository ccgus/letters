//
//  LBMIMEParser.m
//  LetterBox
//
//  Created by Guy English on 10-03-02.
//  Copyright 2010 Kickingbear. All rights reserved.
//

#import "LBMIMEParser.h"
#import "LetterBoxUtilities.h"
#import "LBNSStringAdditions.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

typedef enum {
    LBMIMEParserStateReadingProperties,
    LBMIMEParserStateReadingContent,
    LBMIMEParserStateDetermineBoundry,
    LBMIMEParserStateReadingParts,
    LBMIMEParserStateFinishedReadingParts,
} LBMIMEParserState;


@interface LBMIMEPart (LBMIMEParsing)
- (void)parse:(NSString*)sourceText;
- (NSDictionary*)propertiesFromLines:(NSArray*)lines;
- (NSString*)boundaryFromContentType:(NSString*)contentTypeString;
- (NSString*)valueForAttribute:(NSString*)attribName inPropertyString:(NSString*)property;
@end

@implementation LBMIMEPart
@synthesize content;
@synthesize boundary;

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqual: @"properties"] ) {
        return [NSSet setWithObjects: @"contentType", @"contentID", @"contentTransferEncoding", @"contentDisposition", nil];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

- (id)initWithString:(NSString*)string {
    
    self = [super init];
    
    if (self != nil) {
        
        properties  = [[NSMutableDictionary alloc] init];
        subparts    = [[NSMutableArray alloc] init];
        
        [self parse:string];
    }
    
    return self;
}

- (void)dealloc {

    [subparts release];
    [properties release];
    [content release];
    [boundary release];
    
    [super dealloc];
}



- (LBMIMEPart*)superpart {
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

- (void)addSubpart:(LBMIMEPart *)subpart {
    if (subpart == nil) {
        return;
    }
    
    subpart->superpart = self;
    [subparts addObject:subpart];
}

- (void)removeSubpart:(LBMIMEPart*)subpart {
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

@end


@implementation LBMIMEPart ( LBMIMEParsing )

- (void)parse:(NSString*)sourceText {
    //NSMutableArray *parts = [NSMutableArray array];
    
    //LBMIMEParserState state = LBMIMEParserStateReadingHeader;
    
    NSMutableArray *lines = [NSMutableArray array];
    
    self.boundary = @"--";
    
    NSMutableArray *contentLines = [NSMutableArray array];

    __block LBMIMEParserState state = LBMIMEParserStateReadingProperties;
    
    [sourceText enumerateLinesUsingBlock:^(NSString *string, BOOL *stop) {
        switch (state) {
            
            case LBMIMEParserStateReadingProperties:
                // blank line indicates end of properties block ...
                if ([[string trim] length] == 0) {
                    
                    self.properties = [self propertiesFromLines:lines];
                    self.boundary   = [self boundaryFromContentType:self.contentType];
                    
                    //debug( @"properties: %@", self.properties );
                    //debug( @"boundry: %@", boundry );
                    [lines removeAllObjects];
                    
                    if ([self.contentType hasPrefix:@"multipart/alternative"]) {
                        if (boundary != nil) {
                            state = LBMIMEParserStateReadingContent;
                        }
                        else {
                            state = LBMIMEParserStateDetermineBoundry;
                        }
                    }
                    else {
                        state = LBMIMEParserStateReadingContent;
                    }
                }
                else {
                    if ([string rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location == 0) {
                        if ([lines count] > 0) {
                            NSString *lastLine = [lines objectAtIndex:[lines count] - 1];
                            NSString *concatenatedLine = [lastLine stringByAppendingString:string];
                            [lines removeLastObject];
                            [lines addObject:concatenatedLine];
                        }
                    }
                    else {
                        [lines addObject:string];
                    }
                }
                break;
                
            case LBMIMEParserStateDetermineBoundry:
                
                if ([string hasPrefix:@"--"]) {
                    self.boundary = [string substringFromIndex:2];
                    state = LBMIMEParserStateReadingContent;
                }
                
                break;
                
            case LBMIMEParserStateReadingContent:
                
                if ([string hasPrefix:[NSString stringWithFormat:@"--%@", boundary]]) {
                    [contentLines addObjectsFromArray:lines];
                    [lines removeAllObjects];
                    state = LBMIMEParserStateReadingParts;
                }
                else {
                    if ([lines count] > 0) {
                        
                        NSString *previousLine = [lines objectAtIndex:[lines count] - 1];
                        if ([previousLine hasSuffix:@"="]) {
                            string = [NSString stringWithFormat:@"%@%@", [previousLine substringToIndex:[previousLine length] - 1], string];
                            [lines removeLastObject];
                        }
                    }
                    
                    //NSLog( @"adding content: %@", string );
                    [lines addObject:string];
                }
                break;
                
            case LBMIMEParserStateReadingParts:
                
                if ([string hasPrefix: [NSString stringWithFormat:@"--%@", boundary]]) {
                    NSString *partSourceText = [lines componentsJoinedByString: @"\n"];
                    
                    // guynote: we've got all the text for a subpart here - we can do this in a block async. we'd need to make sure the resulting part was added to the subparts array in the correct position to preserve the "faithfullness" of alternative type ordering.
                    LBMIMEPart *subpart = [[LBMIMEPart alloc] initWithString: partSourceText];
                    [self addSubpart: subpart];
                    [subpart release];
                    
                    [lines removeAllObjects];
                    
                    if ([string isEqual:[NSString stringWithFormat: @"--%@--", boundary]]) {
                        state = LBMIMEParserStateFinishedReadingParts;
                    }
                    else {
                        state = LBMIMEParserStateReadingParts;
                    }
                }
                else {
                    [lines addObject:string];
                }
                break;
                
            case LBMIMEParserStateFinishedReadingParts:
                *stop = YES; // finish enumerating the lines
                break;
        }
    }];
    
    if (state == LBMIMEParserStateReadingContent) {
        [contentLines addObjectsFromArray: lines];
        [lines removeAllObjects];
    }
    
    if (state == LBMIMEParserStateReadingProperties || state == LBMIMEParserStateReadingParts) {
        NSLog(@"MIME message messed up somehow - we didn't hit the terminator");
    }
    
    NSString *newContent = [contentLines componentsJoinedByString:@"\n"];
    NSString *charSet = [self valueForAttribute:@"charset" inPropertyString:self.contentType];
    NSString *transferEncoding = self.contentTransferEncoding;
    
    NSString *decodedNewContent = LBMIMEStringByDecodingStringFromEncodingWithCharSet( newContent, transferEncoding, charSet );
    
    [content release];
    content = [decodedNewContent copy];
    //NSLog( @"content: %@", content );
}

- (NSDictionary*)propertiesFromLines:(NSArray*)lines {
    
    NSMutableDictionary *parsedProperties = [NSMutableDictionary dictionary];
    
    for (NSString *line in lines) {
        NSRange separatorRange = [line rangeOfString:@": "];
        
        if (separatorRange.location != NSNotFound) {
            NSString *key   = [line substringToIndex:separatorRange.location];
            NSString *value = [line substringFromIndex:NSMaxRange(separatorRange)];
            
            if ([key length] && [value length]) {
                value = LBMIMEStringByDecodingEncodedWord(value);
                [parsedProperties setObject:value forKey:[key lowercaseString]];
            }
        }
    }
    
    return parsedProperties;
}

- (NSString*)valueForAttribute:(NSString*)attribName inPropertyString:(NSString*) property {
    
    NSString *attribString = nil;
    NSArray *components = [property componentsSeparatedByString:@";"];
    NSString *attribAssignment = [NSString stringWithFormat:@"%@=", attribName];
    
    for (NSString *component in components) {
        if ([[[component lowercaseString] trim] hasPrefix:attribAssignment]) {
            attribString = [component substringFromIndex:NSMaxRange([component rangeOfString:attribAssignment])];
            
            if ([attribString hasPrefix:@"\""] && [attribString hasSuffix:@"\""]) {
                attribString = [attribString substringWithRange:NSMakeRange(1, [attribString length] - 2)]; // remove the "s on either end
            }
            
            return attribString;
        }
    }
    
    return nil;
}

- (NSString*)boundaryFromContentType:(NSString*)contentTypeString {
    return [self valueForAttribute:@"boundary" inPropertyString:contentTypeString];
}

@end


@implementation LBMIMEMultipartMessage

- (BOOL)isMultipart {
    return [self.contentType hasPrefix:@"multipart/"];
}

- (NSArray*) types {
    NSMutableArray *types = [NSMutableArray array];
    for (LBMIMEPart *part in self.subparts) {
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

- (LBMIMEPart*)availablePartForTypeFromArray:(NSArray*)types {
    
    for (NSString *type in types) {
        LBMIMEPart *part = [self partForType:type];
        if (part) {
             return part;
        }
    }
    
    return nil;
}

- (LBMIMEPart*)partForType:(NSString*)mimeType {
    
    if ([self.contentType hasPrefix:mimeType]) {
        return self;
    }
    
    if ([self isMultipart]) {
        debug(@"yaymuuuuu");
        for (LBMIMEPart *part in self.subparts) {
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

NSString *LBMIMEStringByDecodingPrintedQuoteableWithCharacterSet( NSString *inputString, NSString *characterSet )
{
//    NSMutableData *decodedStringData = [NSMutableData data];
//    BOOL done = NO;
//    NSUInteger characterIndex = 0;
//    while ( !done )
//    {
//        unichar character = [inputString characterAtIndex: characterIndex];
//        characterIndex++;
//        
//        if ( character == '=' )
//        {
//            NSString *hex = [NSString stringWith
//            
//            unichar high = [inputString characterAtIndex: characterIndex];
//            characterIndex++;
//            
//            unichar low = [inputString characterAtIndex: characterIndex];
//            characterIndex++;
//            
//            unichar codePoint = 
//        }
//        else
//        {
//            [decodedStringData appendBytes: &character length: sizeof( unichar )];
//        }
//    }
    return nil;
}

NSString *LBMIMEStringByDecodingStringFromEncodingWithCharSet(NSString *inputString, NSString *transferEncoding, NSString *characterSet)
{
    NSString *decodedString = [NSString stringWithString:inputString];
    
    if ([transferEncoding isEqual: @"quoted-printable"]) {
        //decodedString = [decodedString stringByReplacingOccurrencesOfString:@"=\r\n" withString:@""];
        decodedString = [decodedString stringByReplacingOccurrencesOfString:@"=" withString:@"%"];
        
        if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-1"] ) {
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
        }
        else if ( [characterSet isCaseInsensitiveLike:@"UTF-8"] ) {
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-2"] ) {
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSISOLatin2StringEncoding];
        }
        else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-15"] ) {
            // FIXME : jasonrm - Is this even allowed? From lists of encodings 15 looks to match ISO-8859-15 but I don't like hardcoding a number here.
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:15];
        }
        else if ( [characterSet isCaseInsensitiveLike:@"US-ASCII"] ){
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        }
        else {
            // FIXME : jasonrm - Only the most common (for someone in the US) encodings are supported, everything else is treated like ISO-8859-1
            decodedString = [decodedString stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
        }
    }
    
    if (decodedString == nil) {
        NSLog(@"error decoding!");
        decodedString = inputString;
    }
    
    return decodedString;
}


// RFC 2047 "Encoded Word" Decoder
// http://tools.ietf.org/html/rfc2047
//
NSString *LBMIMEStringByDecodingEncodedWord( NSString *inputString )
{
    #warning Can we remove this and just use the decodedName in LBAddress?
    NSString *encodedWord;
    NSString *encodedSubWord;
    NSRange encodedWordStart = [inputString rangeOfString:@"=?"];
    NSRange encodedWordEnd = [inputString rangeOfString:@"?="];
    NSRange encodedWordRange = NSUnionRange(encodedWordStart, encodedWordEnd);
    
    if ( ! encodedWordRange.length ) {
        // If there are no encoded words, return the name as we have it.
        return inputString;
    }
    
    NSString *decodedName = [NSString stringWithString:inputString];
    
    while ( encodedWordRange.length ) {
        encodedWord = [decodedName substringWithRange:encodedWordRange];
        encodedSubWord = [encodedWord substringFromIndex:2];
        encodedSubWord = [encodedSubWord substringToIndex:[encodedSubWord length] -2];
        
        NSRange characterSetStart = {0,0};
        NSRange characterSetEnd = [encodedSubWord rangeOfString:@"?"];
        characterSetEnd.length = characterSetEnd.length - 1;
        NSRange characterSetRange = NSUnionRange(characterSetStart, characterSetEnd);
        NSString *characterSet = [encodedSubWord substringWithRange:characterSetRange];
        encodedSubWord = [encodedSubWord substringFromIndex:characterSetEnd.location + 1];
        
        if ( [encodedSubWord hasPrefix:@"Q"] || [encodedSubWord hasPrefix:@"q"] ){
            NSString *decodedWord = [encodedSubWord substringFromIndex:2];
            decodedWord = [decodedWord stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            decodedWord = [decodedWord stringByReplacingOccurrencesOfString:@"=" withString:@"%"];
            if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-1"] ) {
                decodedWord = [decodedWord stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"UTF-8"] ) {
                decodedWord = [decodedWord stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-2"] ) {
                decodedWord = [decodedWord stringByReplacingPercentEscapesUsingEncoding:NSISOLatin2StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-15"] ) {
                // FIXME : jasonrm - Is this even allowed? From lists of encodings 15 looks to match ISO-8859-15 but I don't like hardcoding a number here.
                decodedWord = [decodedWord stringByReplacingPercentEscapesUsingEncoding:15];
            } else {
                // FIXME : jasonrm - Only the most common (for someone in the US) encodings are supported, everything else is treated like ISO-8859-1
                decodedWord = [decodedWord stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
            }
            decodedName = [decodedName stringByReplacingOccurrencesOfString:encodedWord withString:decodedWord];
            encodedWordStart = [decodedName rangeOfString:@"=?"];
            encodedWordEnd = [decodedName rangeOfString:@"?="];
            encodedWordRange = NSUnionRange(encodedWordStart, encodedWordEnd);
        } else if ( [encodedSubWord hasPrefix:@"B"] || [encodedSubWord hasPrefix:@"b"] ) {
            NSString *encodedWord = [encodedSubWord substringFromIndex:2];
            NSString *decodedWord;
            
            // FIXME : jasonrm - Something about this doesn't seem right...
            NSData *decodedData = LBMIMEDataByDecodingBase64String( encodedWord );
            
            if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-1"] ) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin1StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"UTF-8"] ) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-2"] ) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin2StringEncoding];
            } else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-8"] ) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:-2147483128];
            } else if ( [characterSet isCaseInsensitiveLike:@"ISO-8859-15"] ) {
                // FIXME : jasonrm - Is this even allowed? From lists of encodings 15 looks to match ISO-8859-15 but I don't like hardcoding a number here.
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:15];
            } else {
                // FIXME : jasonrm - Only the most common (for someone in the US) encodings are supported, everything else is treated like ISO-8859-1
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin1StringEncoding];
            }
            return [decodedWord autorelease];
        }
    }
    return decodedName;
}

NSData *LBMIMEDataByDecodingBase64String( NSString *encodedString )
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