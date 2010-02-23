//
//  LBTCPReader.m
//  LBTCPReader
//
//  Created by August Mueller on 1/31/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBTCPReader.h"
#import "LBTCPConnection.h"
#import "LBNSDataAdditions.h"

@implementation LBTCPReader

- (void)_canRead {
    
    if (canReadBlock) {
        canReadBlock(self);
    }
    else {
        debug(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Reader has data, but nothings being done with it!");
        
        NSLog(@"%@", [self stringFromReadData]);
        
    }
}

- (void)setCanReadBlock:(void (^)(LBTCPReader *))block {
    [canReadBlock release];
    canReadBlock = [block copy];
}

- (NSString*)stringFromReadData {
    
#define MAX_BYTES_READ 2048
    
    NSMutableData *data         = [NSMutableData dataWithLength:MAX_BYTES_READ];
    NSInteger localBytesRead    = [self read:[data mutableBytes] maxLength:MAX_BYTES_READ];
    
    return [[[NSString alloc] initWithBytes:[data bytes] length:localBytesRead encoding:NSUTF8StringEncoding] autorelease];
}


@end
