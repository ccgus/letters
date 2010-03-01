//
//  LBNSDataAdditions.h
//  LetterBox
//
//  Created by August Mueller on 2/21/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (LetterBoxAdditions)

- (NSString*)lbFirstLine;
- (NSString*)lbLastLineOfMultiline;
- (NSString*)lbSingleLineResponse;
- (BOOL)lbEndIsEqualTo:(NSString*)string;

- (NSString*)utf8String;

@end

