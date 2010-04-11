//
//  LBMIMEMessage.h
//  LetterBox
//
//  Created by Alex Morega on 2010-04-04.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LBMIMEMessage : NSObject {
	LBMIMEMessage *superpart; // non-retained
	NSMutableArray *subparts;
	NSString *content;
	NSString *boundary;
	NSMutableArray *headers; // should not be accessed directly
	NSMutableArray *defects;
}

@property (copy) NSString *content;
@property (copy) NSString *boundary;
@property (readonly) NSMutableArray *defects;

+ (LBMIMEMessage*)message;
- (id)init;

- (void)addHeaderWithName:(NSString*)name andValue:(NSString*)value;
- (NSString*)headerValueForName:(NSString*)name;
- (NSString*)contentType;
- (LBMIMEMessage*)superpart;
- (NSArray*)subparts;
- (void)addSubpart:(LBMIMEMessage*)subpart;
- (void)removeSubpart:(LBMIMEMessage*)subpart;
// if this part is base64-encoded, returns decoded data; otherwise returns nil.
- (NSData*)decodedData;
- (BOOL)isMultipart;

- (NSArray*)types;
- (NSString *)availableTypeFromArray:(NSArray *)types;
- (LBMIMEMessage*)partForType:(NSString*)mimeType;
- (LBMIMEMessage*)availablePartForTypeFromArray:(NSArray*) types;

// the MIME spec says the alternative parts are ordered from least faithful to the most faithful. we can only presume the sender has done that correctly. consider this a guess rather than being definitive.
- (NSString*)mostFailthfulAlternativeType;

@end
