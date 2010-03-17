//
//  LBNSStringAdditions.m
//  LetterBox
//
//  Created by August Mueller on 2/28/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBNSStringAdditions.h"
#import "LBNSDataAdditions.h"

#define OBASSERT assert

/* Splits a Supplementary Plane character into two UTF-16 surrogate characters */
/* Do not use this for characters in the Basic Multilinugal Plane */
static inline void OFCharacterToSurrogatePair(UnicodeScalarValue inCharacter, unichar *outUTF16)
{
    UnicodeScalarValue supplementaryPlanePoint = inCharacter - 0x10000;
    
    outUTF16[0] = 0xD800 | ( supplementaryPlanePoint & 0xFFC00 ) >> 10; /* high surrogate */
    outUTF16[1] = 0xDC00 | ( supplementaryPlanePoint & 0x003FF );       /* low surrogate */
}

@implementation NSMutableString (LetterBoxAdditions)




- (void)appendLongCharacter:(UnicodeScalarValue)aCharacter;
{
    unichar utf16[2];
    
    OBASSERT(sizeof(aCharacter)*CHAR_BIT >= 21);
    /* aCharacter must be at least 21 bits to contain a full Unicode character */
    
    if (aCharacter <= 0xFFFF) {
        utf16[0] = (unichar)aCharacter;
        /* There isn't a particularly efficient way to do this using the ObjC interface, so... */
        CFStringAppendCharacters((CFMutableStringRef)self, utf16, 1);
    } else {
        /* Convert Unicode characters in supplementary planes into pairs of UTF-16 surrogates */
        OFCharacterToSurrogatePair(aCharacter, utf16);
        CFStringAppendCharacters((CFMutableStringRef)self, utf16, 2);
    }
}

@end




@implementation NSString (LetterBoxAdditions)

- (NSData*)utf8Data {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)stringByDeletingEndQuotes {
    
    if ([self hasPrefix:@"\""] && [self hasSuffix:@"\""]) {
        return [self substringWithRange:NSMakeRange(1, [self length] - 2)];
    }
    
    return self;
}

- (NSRange)rangeOfString:(NSString*)s startIndex:(NSUInteger)idx {
    return [self rangeOfString:s options:0 range:NSMakeRange(idx, [self length] - idx)];
}

- (NSString*)substringFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex {
    return [self substringWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
}

- (NSString*)trim {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


static NSCharacterSet *nonNonCTLChars = nil;
static NSCharacterSet *nonAtomChars = nil;
static NSCharacterSet *nonAtomCharsExceptLWSP = nil;



+ (void)load {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // Mail header encoding according to RFCs 822 and 2047
    NSCharacterSet *nonCTLChars = [NSCharacterSet characterSetWithRange:(NSRange){32, 95}];
    nonNonCTLChars = [[nonCTLChars invertedSet] retain];
    
    NSMutableCharacterSet *workSet = [nonNonCTLChars mutableCopy];
    [workSet addCharactersInString:@"()<>@,;:\\\".[] "];
    nonAtomChars = [workSet copy];
    
    [workSet removeCharactersInString:@" \t"];
    nonAtomCharsExceptLWSP = [workSet copy];
    
    [workSet release];
    
    [pool release];
}



- (NSString *)asRFC822Word
{
    if ([self length] > 0 &&
        [self rangeOfCharacterFromSet:nonAtomChars].length == 0 &&
        !([self hasPrefix:@"=?"] && [self hasSuffix:@"?="])) {
        /* We're an atom. */
        return [[self copy] autorelease];
    }
    
    /* The nonNonCTLChars set has a wacky name, but what the heck. It contains all the characters that we are not willing to represent in a quoted-string. Technically, we're allowed to have qtext, which is "any CHAR excepting <">, "\" & CR, and including linear-white-space" (RFC822 3.3); CHAR means characters 0 through 127 (inclusive), and so a qtext may contain arbitrary ASCII control characters. But to be on the safe side, we don't include those. */
    /* TODO: Consider adding a few specific control characters, perhaps HTAB */
    
    if ([self rangeOfCharacterFromSet:nonNonCTLChars].length == 0) {
        /* We don't contain any characters that aren't "nonCTLChars", so we can be represented as a quoted-string. */
        NSMutableString *buffer = [self mutableCopy];
        NSString *result;
        NSUInteger chIndex = [buffer length];
        
        while (chIndex > 0) {
            unichar ch = [buffer characterAtIndex:(-- chIndex)];
            OBASSERT( !( ch < 32 || ch >= 127 ) ); // guaranteed by definition of nonNonCTLChars
            if (ch == '"' || ch == '\\' /* || ch < 32 || ch >= 127 */) {
                [buffer replaceCharactersInRange:(NSRange){chIndex, 0} withString:@"\\"];
            }
        }
        
        [buffer replaceCharactersInRange:(NSRange){0, 0} withString:@"\""];
        [buffer appendString:@"\""];
        
        result = [[buffer copy] autorelease];
        [buffer release];
        
        return result;
    }
    
    /* Otherwise, we cannot be represented as an RFC822 word (atom or quoted-string). If appropriate, the caller can use the RFC2047 encoded-word format. */
    return nil;
}

/* Preferred encodings as alluded in RFC2047 */
static const CFStringEncoding preferredEncodings[] = {
    kCFStringEncodingISOLatin1,
    kCFStringEncodingISOLatin2,
    kCFStringEncodingISOLatin3,
    kCFStringEncodingISOLatin4,
    kCFStringEncodingISOLatinCyrillic,
    kCFStringEncodingISOLatinArabic,
    kCFStringEncodingISOLatinGreek,
    kCFStringEncodingISOLatinHebrew,
    kCFStringEncodingISOLatin5,
    kCFStringEncodingISOLatin6,
    kCFStringEncodingISOLatinThai,
    kCFStringEncodingISOLatin7,
    kCFStringEncodingISOLatin8,
    kCFStringEncodingISOLatin9,
    kCFStringEncodingInvalidId /* sentinel */
};

/* Some encodings we like, which we try out if preferredEncodings fails */
static const CFStringEncoding desirableEncodings[] = {
    kCFStringEncodingUTF8,
    kCFStringEncodingUnicode,
    kCFStringEncodingHZ_GB_2312,
    kCFStringEncodingISO_2022_JP_1,
    kCFStringEncodingInvalidId /* sentinel */
};


/* Characters which do not need to be quoted in an RFC2047 quoted-printable-encoded word.
 Note that 0x20 is treated specially by the routine that uses this bitmap. */
static const char qpNonSpecials[128] = {
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    0, 0, 0, 0, 0, 0, 0, 0,   //  
    1, 1, 0, 0, 0, 0, 0, 0,   //  SP and !
    0, 0, 1, 1, 0, 1, 0, 1,   //    *+ - /
    1, 1, 1, 1, 1, 1, 1, 1,   //  01234567
    1, 1, 0, 0, 0, 0, 0, 0,   //  89
    0, 1, 1, 1, 1, 1, 1, 1,   //   ABCDEFG
    1, 1, 1, 1, 1, 1, 1, 1,   //  HIJKLMNO
    1, 1, 1, 1, 1, 1, 1, 1,   //  PQRSTUVW
    1, 1, 1, 0, 0, 0, 0, 0,   //  XYZ
    0, 1, 1, 1, 1, 1, 1, 1,   //   abcdefg
    1, 1, 1, 1, 1, 1, 1, 1,   //  hijklmno
    1, 1, 1, 1, 1, 1, 1, 1,   //  pqrstuvw
    1, 1, 1, 0, 0, 0, 0, 0    //  xyz
};


static inline unichar hex(int i)
{
    static const char hexDigits[16] = {
        '0', '1', '2', '3', '4', '5', '6', '7',
        '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
    };
    
    return (unichar)hexDigits[i];
}



/* TODO: RFC2047 requires us to break up encoded-words so that each one is no longer than 75 characters. We don't do that, which means it's possible for us to produce non-conforming tokens if called on a long string. */
- (NSString *)asRFC2047EncodedWord
{
    CFStringRef cfSelf = (CFStringRef)self;
    
    CFStringEncoding bestEncoding = kCFStringEncodingInvalidId, fastestEncoding = CFStringGetFastestEncoding(cfSelf);
    for (unsigned encodingIndex = 0; preferredEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
        if (fastestEncoding == preferredEncodings[encodingIndex]) {
            bestEncoding = fastestEncoding;
            break;
        }
    }
    
    CFDataRef convertedBytes = NULL;
    if (bestEncoding == kCFStringEncodingInvalidId) {
        // The fastest encoding is not in the preferred encodings list. Check whether any of the preferred encodings are possible at all.
        
        for (unsigned encodingIndex = 0; preferredEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
            convertedBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, preferredEncodings[encodingIndex], 0);
            if (convertedBytes != NULL) {
                bestEncoding = preferredEncodings[encodingIndex];
                break;
            }
        }
    }
    
    if (bestEncoding == kCFStringEncodingInvalidId) {
        // We can't use any of the preferred encodings, so use the smallest one.
        bestEncoding = CFStringGetSmallestEncoding(cfSelf);
    }
    
    if (convertedBytes == NULL)
        convertedBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, bestEncoding, 0);
    
    // CFStringGetSmallestEncoding() doesn't always return the smallest encoding, so try out a few others on our own
    {
        CFStringEncoding betterEncoding = kCFStringEncodingInvalidId;
        CFDataRef betterBytes = NULL;
        
        for (unsigned encodingIndex = 0; desirableEncodings[encodingIndex] != kCFStringEncodingInvalidId; encodingIndex ++) {
            CFDataRef alternateBytes;
            CFStringEncoding trialEncoding;
            if (desirableEncodings[encodingIndex] == bestEncoding)
                continue;
            trialEncoding = desirableEncodings[encodingIndex];
            alternateBytes = CFStringCreateExternalRepresentation(kCFAllocatorDefault, cfSelf, trialEncoding, 0);
            if (alternateBytes != NULL) {                
                if (betterBytes == NULL) {
                    betterEncoding = trialEncoding;
                    betterBytes = alternateBytes;
                } else if(CFDataGetLength(betterBytes) > CFDataGetLength(alternateBytes)) {
                    CFRelease(betterBytes);
                    betterEncoding = trialEncoding;
                    betterBytes = alternateBytes;
                } else {
                    CFRelease(alternateBytes);
                }
            }
        }
        
        if (betterBytes != NULL) {
            if (CFDataGetLength(betterBytes) < CFDataGetLength(convertedBytes)) {
                CFRelease(convertedBytes);
                convertedBytes = betterBytes;
                bestEncoding = betterEncoding;
            } else {
                CFRelease(betterBytes);
            }
        }
    }
    
    OBASSERT(bestEncoding != kCFStringEncodingInvalidId);
    OBASSERT(convertedBytes != NULL);
    
    // On 10.5 this returned uppercase, but it might not always.
    NSString *charsetName = [(NSString *)CFStringConvertEncodingToIANACharSetName(bestEncoding) lowercaseString];
    
    // Hack for UTF16BE/UTF16LE.
    // Note that this doesn't screw up our byte count because we remove two bytes here but add two bytes in the encoding name.
    // We might still come out ahead because BASE64 is like that.
    if ([charsetName isEqualToString:@"utf-16"] && CFDataGetLength(convertedBytes) >= 2) {
        UInt8 maybeBOM[2];
        BOOL stripBOM = NO;
        
        CFDataGetBytes(convertedBytes, (CFRange){0,2},maybeBOM);
        if (maybeBOM[0] == 0xFE && maybeBOM[1] == 0xFF) {
            charsetName = @"utf-16be";
            stripBOM = YES;
        } else if (maybeBOM[0] == 0xFF && maybeBOM[1] == 0xFE) {
            charsetName = @"utf-16le";
            stripBOM = YES;
        }
        
        if (stripBOM) {
            CFMutableDataRef stripped = CFDataCreateMutableCopy(kCFAllocatorDefault, CFDataGetLength(convertedBytes), convertedBytes);
            CFDataDeleteBytes(stripped, (CFRange){0,2});
            CFRelease(convertedBytes);
            convertedBytes = stripped;
        }
    }
    
    NSUInteger byteCount = CFDataGetLength(convertedBytes);
    const UInt8 *bytePtr = CFDataGetBytePtr(convertedBytes);
    
    // Now decide whether to use quoted-printable or base64 encoding. Again, we choose the smallest size.
    NSUInteger qpSize = 0;
    for (NSUInteger byteIndex = 0; byteIndex < byteCount; byteIndex ++) {
        if (bytePtr[byteIndex] < 128 && qpNonSpecials[bytePtr[byteIndex]])
            qpSize += 1;
        else
            qpSize += 3;
    }
    
    NSUInteger b64Size = (( byteCount + 2 ) / 3) * 4;
    
    NSString *encodedWord;
    if (b64Size < qpSize) {
        // Base64 is smallest. Use it.
        encodedWord = [NSString stringWithFormat:@"=?%@?B?%@?=", charsetName, [(NSData *)convertedBytes base64Encoding]];
    } else {
        NSMutableString *encodedContent;
        // Quoted-Printable is smallest (or, at least, not larger than Base64).
        // (Ties go to QP because it's more readable.)
        encodedContent = [[NSMutableString alloc] initWithCapacity:qpSize];
        for (NSUInteger byteIndex = 0; byteIndex < byteCount; byteIndex ++) {
            UInt8 byte = bytePtr[byteIndex];
            if (byte < 128 && qpNonSpecials[byte]) {
                if (byte == 0x20) /* RFC2047 4.2(2) */
                    byte = 0x5F;
                [encodedContent appendLongCharacter:byte];
            } else {
                unichar highNybble, lowNybble;
                
                highNybble = hex((byte & 0xF0) >> 4);
                lowNybble = hex(byte & 0x0F);
                [encodedContent appendLongCharacter:'='];
                [encodedContent appendLongCharacter:highNybble];
                [encodedContent appendLongCharacter:lowNybble];
            }
        }
        encodedWord = [NSString stringWithFormat:@"=?%@?Q?%@?=", charsetName, encodedContent];
        [encodedContent release];
    }
    
    CFRelease(convertedBytes);
    
    return encodedWord;
}

- (NSString *)asRFC2047Phrase
{
    NSString *result;
    
    if ([self rangeOfCharacterFromSet:nonAtomCharsExceptLWSP].length == 0) {
        /* We look like a sequence of atoms. However, we need to check for strings like "foo =?bl?e?gga?= bar", which have special semantics described in RFC2047. (This test is a little over-cautious but that's OK.) */
        
        if (!([self rangeOfString:@"=?"].length > 0 &&
              [self rangeOfString:@"?="].length > 0))
            return self;
    }
    
    /* -asRFC822Word will produce a single double-quoted string for all our text; e.g. if called with [John Q. Public] we'll return ["John Q. Public"] rather than [John "Q." Public]. */
    result = [self asRFC822Word];
    
    /* If we can't be represented as an RFC822 word, use the extended syntax from RFC2047. */
    if (result == nil)
        result = [self asRFC2047EncodedWord];
    
    return result;
}








@end
