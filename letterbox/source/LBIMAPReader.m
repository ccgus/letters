//
//  LBIMAPReader.m
//  LBIMAPTest
//
//  Created by August Mueller on 1/31/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBIMAPReader.h"
#import "LBIMAPConnection.h"

@implementation LBIMAPReader

- (void) _canRead {
    
    [(LBIMAPConnection*)_conn canRead:self];
    
}

@end
