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
    
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    if (canReadBlock) {
        debug(@"calling the block");
        canReadBlock(self);
    }
    else {
        // sometimes, our connection is also LBSMTPConnection.  It just happens to implement canRead: as well.
        [(LBTCPConnection*)_conn canRead:self];
    }
}

- (void) setCanReadBlock:(void (^)(LBTCPReader *))block {
    [canReadBlock release];
    canReadBlock = [block copy];
}

@end
