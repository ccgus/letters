//
//  Base64.h
//  MYUtilities
//
//  Created by Jens Alfke on 1/27/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//NOTE: Using this requires linking against /usr/lib/libcrypto.dylib.


@interface NSData (MYBase64)

- (NSString *)my_base64String;
- (NSString *)my_base64StringWithNewlines:(BOOL)encodeWithNewlines;

- (NSData *)my_decodeBase64;
- (NSData *)my_decodeBase64WithNewLines:(BOOL)encodedWithNewlines;

- (NSString *)my_hexString;
- (NSString *)my_hexDump;

@end
