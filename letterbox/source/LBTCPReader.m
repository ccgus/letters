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
    
    // sometimes, our connection is also LBSMTPConnection.  It just happens to implement canRead: as well.
    [(LBTCPConnection*)_conn canRead:self];
    
}

@end
