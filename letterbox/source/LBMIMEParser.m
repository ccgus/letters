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


@implementation LBMIMEParser

+ (LBMIMEMessage*)messageFromString:(NSString*)sourceText {
    LBMIMEMessage *message = [LBMIMEMessage message];
    
    NSMutableArray *lines = [NSMutableArray array];
    
    NSMutableArray *contentLines = [NSMutableArray array];

    __block LBMIMEParserState state = LBMIMEParserStateReadingProperties;
    
    [sourceText enumerateLinesUsingBlock:^(NSString *string, BOOL *stop) {
        switch (state) {
            
            case LBMIMEParserStateReadingProperties:
                // blank line indicates end of properties block ...
                if ([[string trim] length] == 0) {
                    
                    message.properties = [self headersFromLines:lines defects:nil];
                    message.boundary   = [self boundaryFromContentType:message.contentType];
                    
                    //debug( @"properties: %@", message.properties );
                    //debug( @"boundary: %@", message.boundary );
                    [lines removeAllObjects];
                    
                    if ([[message.contentType lowercaseString] hasPrefix:@"multipart/"]) {
                        if (message.boundary != nil) {
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
                    message.boundary = [string substringFromIndex:2];
                    state = LBMIMEParserStateReadingContent;
                }
                
                break;
                
            case LBMIMEParserStateReadingContent:
                if ([string hasPrefix:[NSString stringWithFormat:@"--%@", message.boundary]]) {
                    [contentLines addObjectsFromArray:lines];
                    [lines removeAllObjects];
                    state = LBMIMEParserStateReadingParts;
                }
                else {
                    [lines addObject:string];
                }
                break;
                
            case LBMIMEParserStateReadingParts:
                
                if ([string hasPrefix: [NSString stringWithFormat:@"--%@", message.boundary]]) {
                    [lines addObject:@""];
                    NSString *partSourceText = [lines componentsJoinedByString: @"\n"];
                    
                    // guynote: we've got all the text for a subpart here - we can do this in a block async. we'd need to make sure the resulting part was added to the subparts array in the correct position to preserve the "faithfullness" of alternative type ordering.
                    LBMIMEMessage *subpart = [LBMIMEParser messageFromString:partSourceText];
                    [message addSubpart:subpart];
                    [subpart release];
                    
                    [lines removeAllObjects];
                    
                    if ([string isEqual:[NSString stringWithFormat: @"--%@--", message.boundary]]) {
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
    NSString *charSet = [self valueForAttribute:@"charset" inPropertyString:message.contentType];
    NSString *transferEncoding = message.contentTransferEncoding;
    
    NSString *decodedNewContent = LBMIMEStringByDecodingStringFromEncodingWithCharSet( newContent, transferEncoding, charSet );
    
    [message.content release];
    message.content = [decodedNewContent copy];
    
    return message;
}

+ (NSDictionary*)headersFromLines:(NSArray*)lines defects:(NSMutableArray*)parseDefects {
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    NSString *lastHeader = nil;
    NSString *lastValue = nil;
    NSCharacterSet *blanks = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    for (NSString *line in lines) {
        if ([line hasPrefix:@" "] || [line hasPrefix:@"\t"]) {
            if (lastValue == nil) {
                if (parseDefects != nil)
                    [parseDefects addObject:[NSString stringWithFormat: @"Unexpected header continuation: \"%@\"", line]];
                continue;
            }
            
            line = [line stringByTrimmingCharactersInSet: blanks];
            line = [@" " stringByAppendingString:line];
            lastValue = [lastValue stringByAppendingString: line];
            continue;
        }
        
        if (lastHeader != nil) {
            // TODO: preserve case of header keys, but allow for case-insensitive retrieval
            [headers setObject:lastValue forKey:[lastHeader lowercaseString]];
            lastHeader = nil;
            lastValue = nil;
        }
        
        NSRange separatorRange = [line rangeOfString:@": "];
        
        if (separatorRange.location == NSNotFound) {
            if (parseDefects != nil)
                [parseDefects addObject:[NSString stringWithFormat: @"Malformed header: \"%@\"", line]];
            continue;
        }
        
        lastHeader = [line substringToIndex:separatorRange.location];
        lastValue = [line substringFromIndex:NSMaxRange(separatorRange)];
    }
    
    if (lastHeader != nil) {
        // TODO: preserve case of header keys, but allow for case-insensitive retrieval
        [headers setObject:lastValue forKey:[lastHeader lowercaseString]];
    }
    
    return headers;
}

+ (NSString*)valueForAttribute:(NSString*)attribName inPropertyString:(NSString*) property {
    
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

+ (NSString*)boundaryFromContentType:(NSString*)contentTypeString {
    NSString *rough_value = [self valueForAttribute:@"boundary" inPropertyString:contentTypeString];
    return [rough_value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
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
        decodedString = [decodedString stringByReplacingOccurrencesOfString:@"=\n" withString:@""];
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