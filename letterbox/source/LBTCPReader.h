//
//  LBTCPReader.h
//  LBTCPReader
//
//  Created by August Mueller on 1/31/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPStream.h"

@interface LBTCPReader : TCPReader {
    void (^canReadBlock)(LBTCPReader *);
}

- (void)setCanReadBlock:(void (^)(LBTCPReader *))block;
- (NSString*)stringFromReadData;

@end
