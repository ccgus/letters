//
//  LBNSStringAdditions.m
//  LetterBox
//
//  Created by August Mueller on 2/28/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBNSStringAdditions.h"


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

@end
