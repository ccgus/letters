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
#import "LBNSStringAdditions.h"
#import "LBNSDataAdditions.h"

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

/*
http://tools.ietf.org/html/rfc2047

   encoded-word = "=?" charset "?" encoding "?" encoded-text "?="

   charset = token    ; see section 3

   encoding = token   ; see section 4

   token = 1*<Any CHAR except SPACE, CTLs, and especials>

   especials = "(" / ")" / "<" / ">" / "@" / "," / ";" / ":" / "
               <"> / "/" / "[" / "]" / "?" / "." / "="

   encoded-text = 1*<Any printable ASCII character other than "?"
                     or SPACE>
                  ; (but see "Use of encoded-words in message
                  ; headers", section 5)
*/
- (NSString*)decodedName {
    
    if ([name rangeOfString:@"=?"].location == NSNotFound) {
        return name;
    }
    
    NSMutableString *retString  = [NSMutableString string];
    
    NSUInteger currentIdx = 0;
    
    while (currentIdx < [name length]) {
        NSRange csStart = [name rangeOfString:@"=?" startIndex:currentIdx];
        
        if (csStart.location == NSNotFound) {
            break;
        }
        
        currentIdx = NSMaxRange(csStart);
        
        NSRange csEnd = [name rangeOfString:@"?" startIndex:currentIdx];
        currentIdx = NSMaxRange(csEnd);
        
        NSRange encEnd = [name rangeOfString:@"?" startIndex:currentIdx];
        currentIdx = NSMaxRange(encEnd);
        
        NSRange encTEnd = [name rangeOfString:@"?=" startIndex:currentIdx];
        currentIdx = NSMaxRange(encTEnd);
        
        NSString *charset   = [name substringFromIndex:NSMaxRange(csStart) toIndex:csEnd.location];
        NSString *encoding  = [[name substringFromIndex:NSMaxRange(csEnd) toIndex:encEnd.location] lowercaseString];
        NSString *text      = [name substringFromIndex:NSMaxRange(encEnd) toIndex:encTEnd.location];
        
        debug(@"charset: '%@'", charset);
        debug(@"encoding: '%@'", encoding);
        debug(@"text: '%@'", text);
        
        if ([encoding isEqualToString:@"q"]) {
            
            text = [text stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            text = [text stringByReplacingOccurrencesOfString:@"=" withString:@"%"];
            
            if ([charset isCaseInsensitiveLike:@"ISO-8859-1"]) {
                text = [text stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"UTF-8"]) {
                text = [text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"ISO-8859-2"]) {
                text = [text stringByReplacingPercentEscapesUsingEncoding:NSISOLatin2StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"ISO-8859-15"]) {
                // FIXME : jasonrm - Is this even allowed? From lists of encodings 15 looks to match ISO-8859-15 but I don't like hardcoding a number here.
                text = [text stringByReplacingPercentEscapesUsingEncoding:15];
            }
            else {
                // FIXME : jasonrm - Only the most common (for someone in the US) encodings are supported, everything else is treated like ISO-8859-1
                text = [text stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
            }
            
            [retString appendString:text];
            
        }
        
        else if ([encoding isEqualToString:@"b"]) {
            
            NSString *decodedWord;
            
            // FIXME : jasonrm - Something about this doesn't seem right...
            NSData *decodedData = [NSData dataWithBase64EncodedString:text];
            
            if ([charset isCaseInsensitiveLike:@"ISO-8859-1"]) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin1StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"UTF-8"]) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"ISO-8859-2"]) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin2StringEncoding];
            }
            else if ([charset isCaseInsensitiveLike:@"ISO-8859-8"]) {
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:-2147483128];
            }
            else if ([charset isCaseInsensitiveLike:@"ISO-8859-15"]) {
                // FIXME : jasonrm - Is this even allowed? From lists of encodings 15 looks to match ISO-8859-15 but I don't like hardcoding a number here.
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:15];
            }
            else {
                // FIXME : jasonrm - Only the most common (for someone in the US) encodings are supported, everything else is treated like ISO-8859-1
                decodedWord = [[NSString alloc] initWithData:decodedData encoding:NSISOLatin1StringEncoding];
            }
            
            return [decodedWord autorelease];
        }
    }
    
    if (currentIdx < [name length]) {
        [retString appendString:[name substringFromIndex:currentIdx]];
    }
    
    return retString;
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
