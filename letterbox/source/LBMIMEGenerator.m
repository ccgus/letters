//
//  LBMIMEGenerator.m
//  LetterBox
//
//  Created by Alex Morega on 2010-04-12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LBMIMEGenerator.h"


@implementation LBMIMEGenerator

+ (NSString*)stringFromMessage:(LBMIMEMessage*)message {
    NSMutableArray *outputLines = [NSMutableArray array];
    
    for (NSArray *header in message.headers) {
        NSString *encodedHeader = [NSString stringWithFormat:@"%@: %@",
                                   [header objectAtIndex:0],
                                   [header objectAtIndex:1]];
        [outputLines addObject:encodedHeader];
    }
    [outputLines addObject:@""];
    
    if ([message isMultipart]) {
        NSString *boundary = [message multipartBoundary];
        for (LBMIMEMessage *part in message.subparts) {
            [outputLines addObject:[NSString stringWithFormat:@"--%@", boundary]];
            [outputLines addObject:[LBMIMEGenerator stringFromMessage:part]];
        }
        [outputLines addObject:[NSString stringWithFormat:@"--%@--", boundary]];
    }
    else {
        [outputLines addObject:[message content]];
    }
    
    return [outputLines componentsJoinedByString:@"\r\n"];
}

@end
