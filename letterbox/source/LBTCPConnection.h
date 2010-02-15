//
//  LBTCPConnection.h
//  LetterBox
//
//  Created by August Mueller on 2/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBActivity.h"
#import "TCPConnection.h"

@class LBTCPReader;

#define CRLF "\r\n"
typedef void (^LBResponseBlock)(NSError *);

@interface LBTCPConnection : TCPConnection  <TCPConnectionDelegate, LBActivity> {
    void (^responseBlock)(NSError *);
    
    NSString    *activityStatus;
}

@property (assign) BOOL shouldCancelActivity;
@property (assign) BOOL debugOutput;
@property (retain) NSMutableData *responseBytes;

- (void)canRead:(LBTCPReader*)reader;
- (void)setActivityStatusAndNotifiy:(NSString *)value;

@end
