//
//  LBMIMEParser.h
//  LetterBox
//
//  Created by Guy English on 10-03-02.
//  Copyright 2010 Kickingbear. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBMIMEMessage.h"

// E-mail (RFC 2822) message parser
@interface LBMIMEParser : NSObject

// Parse |sourceText| and create one LBMIMEMessage object. If the content is
// multipart, the parser is called recursively, so the output will contain a
// tree of message objects.
+ (LBMIMEMessage*)messageFromString:(NSString*)sourceText;

// Parse |lines| (assumed to be list of NSString) as message headers. The
// output is a list of NSArray items, each with two values: header name and
// header value. If |parsingDefects| is not nil, any problems encountered are
// appended to it as strings.
+ (NSArray*)headersFromLines:(NSArray*)lines defects:(NSMutableArray*)parsingDefects;

@end


NSString *LBMIMEStringByDecodingPrintedQuoteableWithCharacterSet( NSString *inputString, NSString *characterSet );
NSString *LBMIMEStringByDecodingEncodedWord( NSString *inputString );
