/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRELB, INDIRELB, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRALB, STRILB
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#import "LBAddress.h"
#import "LetterBoxUtilities.h"

@implementation LBAddress

@synthesize email;
@synthesize name;

+ (id)address {
    LBAddress *aAddress = [[LBAddress alloc] init];
    return [aAddress autorelease];
}


+ (id)addressWithName:(NSString *)aName email:(NSString *)aEmail {
    LBAddress *aAddress = [[LBAddress alloc] initWithName:aName email:aEmail];
    return [aAddress autorelease];
}


- (id)initWithName:(NSString *)aName email:(NSString *)aEmail {
    self = [super init];
    if (self) {
        [self setName:aName];
        [self setEmail:aEmail];
    }
    return self;
}


- (id)init {
    self = [super init];
    if (self) {
        [self setName:@""];
        [self setEmail:@""];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    [self setName:[aDecoder decodeObjectForKey:@"name"]];
    [self setEmail:[aDecoder decodeObjectForKey:@"email"]];
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:email forKey:@"email"];
    [aCoder encodeObject:name forKey:@"name"];
}


- (void)dealloc {
    [email release];
    [name release];
    [super dealloc];
}

// RFC 2047 "Encoded Word" Decoder
// http://tools.ietf.org/html/rfc2047
//
-(NSString*)decodedName {
    NSString *encodedWord;
    NSString *encodedSubWord;
    NSRange encodedWordStart = [name rangeOfString:@"=?"];
    NSRange encodedWordEnd = [name rangeOfString:@"?="];
    NSRange encodedWordRange = NSUnionRange(encodedWordStart, encodedWordEnd);

    if ( ! encodedWordRange.length ) {
        // If there are no encoded words, return the name as we have it.
        return name;
    }

    NSString *decodedName = [NSString stringWithString:name];

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
            NSData *decodedData = [LBAddress dataByDecodingBase64String:encodedWord];

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

+ (NSData *)dataByDecodingBase64String:(NSString *)encodedString {
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

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[LBAddress class]]) {
        return NO;
    }
        
    return [[object name] isEqualToString:[self name]] && [[object email] isEqualToString:[self email]];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ %@ <%@>)", [super description], name, email];
}

@end
