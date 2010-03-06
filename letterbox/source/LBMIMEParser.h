//
//  LBMIMEParser.h
//  LetterBox
//
//  Created by Guy English on 10-03-02.
//  Copyright 2010 Kickingbear. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LBMIMEPart : NSObject
{
	LBMIMEPart *superpart; // non-retained
	NSMutableArray *subparts;
	
	NSString *content;
	NSString *boundary;
	NSMutableDictionary *properties;
}

// parses the string, pull out the properties and sets the content up as required. additionally, if the content is multi-part, will create a subtree of parts recursively.
- (id) initWithString: (NSString*) string;

@property (copy) NSString *content;

@property (copy) NSString *contentType;
@property (copy) NSString *contentID;
@property (copy) NSString *contentDisposition;
@property (copy) NSString *contentTransferEncoding;
@property (copy) NSDictionary *properties; // all the properties in key value pairs.

- (LBMIMEPart*) superpart;
- (NSArray*) subparts;
- (void) addSubpart: (LBMIMEPart*) subpart;
- (void) removeSubpart: (LBMIMEPart*) subpart;

@end


@interface LBMIMEMultipartMessage : LBMIMEPart
{
}

- (BOOL) isMultipartAlternative;

- (NSArray*) types;
- (NSString *)availableTypeFromArray:(NSArray *)types;
- (LBMIMEPart*) partForType: (NSString*) mimeType;
- (LBMIMEPart*) availablePartForTypeFromArray: (NSArray*) types;

// the MIME spec says the alternative parts are ordered from least faithful to the most faithful. we can only presume the sender has done that correctly. consider this a guess rather than being definitive.
- (NSString*) mostFailthfulAlternativeType;

@end


NSString *LBMIMEStringByDecodingPrintedQuoteableWithCharacterSet( NSString *inputString, NSString *characterSet );
NSString *LBMIMEStringByDecodingStringFromEncodingWithCharSet( NSString *inputString, NSString *transferEncoding, NSString *charSet );
NSString *LBMIMEStringByDecodingEncodedWord( NSString *inputString );
NSData *LBMIMEDataByDecodingBase64String( NSString *encodedString );
