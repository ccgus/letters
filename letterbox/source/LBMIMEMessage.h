//
//  LBMIMEMessage.h
//  LetterBox
//
//  Created by Alex Morega on 2010-04-04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// An in-memory representation of a MIME message, with headers and a payload.
// 
// Instances of LBMIMEMessage are generally created by calling LBMIMEParser to
// parse an RFC 2822 email message. It's also possible to construct new
// messages and modify existing ones. A yet-to-be implemented class,
// LBMIMEGenerator, will handle converting the message back to RFC 2822
// format.
// 
// Messages contain a set of headers which can be queried, appended and
// deleted. Header names are stored preserving their case, but queries are
// case-insensitive.
// 
// Messages also contain one or more payloads. The payload is either a string
// (if isMultipart is NO) or a list of LBMIMEMessage objects (if isMultipart
// is YES).
// 
// LBMIMEMessage, LBMIMEParser and LBMIMEGenerator are modelled after Python's
// email module, which informs their interface and implementation.
@interface LBMIMEMessage : NSObject {
	LBMIMEMessage *superpart; // non-retained
	NSMutableArray *subparts;
	NSString *content;
	NSMutableArray *headers; // should not be accessed directly
	NSMutableArray *defects;
}

@property (copy) NSString *content;
@property (readonly) NSMutableArray *defects;

// Create a new blank message
+ (LBMIMEMessage*)message;
- (id)init;

// Append a header to the headers list. Does not override previous headers
// with the same name.
- (void)addHeaderWithName:(NSString*)name andValue:(NSString*)value;

// Get the first header that matches |name| (case-insensitive comparison).
// Returns nil if no matching header is found.
- (NSString*)headerValueForName:(NSString*)name;

// Get the value of the "Content-Type" header.
- (NSString*)contentType;
- (LBMIMEMessage*)superpart;
- (NSArray*)subparts;
- (void)addSubpart:(LBMIMEMessage*)subpart;
- (void)removeSubpart:(LBMIMEMessage*)subpart;

// If the payload is base64-encoded, returns decoded data; otherwise returns nil.
- (NSData*)contentTransferDecoded;

// Returns YES if the message content main type is "multipart".
- (BOOL)isMultipart;

// Returns boundary that separates subparts
- (NSString*)multipartBoundary;

// Get a parameter from the "Content-Type" header.
- (NSString*)contentTypeAttribute:(NSString*)attribName;

@end

NSData* LBMIMEDataFromQuotedPrintable(NSString* value);
NSData* LBMIMEDataFromBase64(NSString* encodedString);
