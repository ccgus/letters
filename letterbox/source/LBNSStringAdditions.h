//
//  LBNSStringAdditions.h
//  LetterBox
//
//  Created by August Mueller on 2/28/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (LetterBoxAdditions)

- (NSData*)utf8Data;
- (NSString*)stringByDeletingEndQuotes;
- (NSString *)asRFC2047Phrase;

- (NSRange)rangeOfString:(NSString*)s startIndex:(NSUInteger)idx;

- (NSString*)substringFromIndex:(NSUInteger)startIndex toIndex:(NSUInteger)endIndex;

- (NSString*)trim;

@end
