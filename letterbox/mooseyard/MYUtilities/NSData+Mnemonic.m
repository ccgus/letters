//
//  NSData+Mnemonic.m
//  Cloudy
//
//  Created by Jens Alfke on 6/24/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "NSData+Mnemonic.h"
#import "mnemonic.h"


@implementation NSData (Mnemonic)

- (NSString*) my_mnemonic {
    NSMutableData *chars = [NSMutableData dataWithLength: 10*mn_words_required(self.length)];
    if (!chars)
        return nil;
    int result = mn_encode((void*)self.bytes, self.length,
                           chars.mutableBytes, chars.length,
                           MN_FDEFAULT);
    if (result != 0) {
        Warn(@"Mnemonic encoder failed: err=%i",result);
        return nil;
    }
    return [[[NSString alloc] initWithUTF8String: chars.mutableBytes] autorelease];
}

@end
