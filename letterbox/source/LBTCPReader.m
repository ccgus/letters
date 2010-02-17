//
//  LBTCPReader.m
//  LBTCPReader
//
//  Created by August Mueller on 1/31/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBTCPReader.h"
#import "LBTCPConnection.h"

@implementation LBTCPReader

- (void) _canRead {
    
    if (canReadBlock) {
        canReadBlock(self);
    }
    else {
        debug(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Reader has data, but nothings being done with it!");
        assert(NO);
    }
}

- (void) setCanReadBlock:(void (^)(LBTCPReader *))block {
    [canReadBlock release];
    canReadBlock = [block copy];
}

@end
