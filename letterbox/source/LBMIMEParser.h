//
//  LBMIMEParser.h
//  LetterBox
//
//  Created by Guy English on 10-03-02.
//  Copyright 2010 Kickingbear. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBMIMEMessage.h"

@interface LBMIMEParser : NSObject

// parses the string, pull out the properties and sets the content up as required. additionally, if the content is multi-part, will create a subtree of parts recursively.
+ (LBMIMEMessage*)messageFromString:(NSString*)sourceText;
+ (NSDictionary*)headersFromLines:(NSArray*)lines defects:(NSMutableArray*)parseDefects;
+ (NSString*)boundaryFromContentType:(NSString*)contentTypeString;
+ (NSString*)valueForAttribute:(NSString*)attribName inPropertyString:(NSString*)property;

@end


NSString *LBMIMEStringByDecodingPrintedQuoteableWithCharacterSet( NSString *inputString, NSString *characterSet );
NSString *LBMIMEStringByDecodingStringFromEncodingWithCharSet( NSString *inputString, NSString *transferEncoding, NSString *charSet );
NSString *LBMIMEStringByDecodingEncodedWord( NSString *inputString );
NSData *LBMIMEDataByDecodingBase64String( NSString *encodedString );
