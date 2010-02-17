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
#import "LBTCPReader.h"

extern NSString *LBCONNECTING;

#define CRLF "\r\n"
typedef void (^LBResponseBlock)(NSError *);

@interface LBTCPConnection : TCPConnection  <TCPConnectionDelegate, LBActivity> {
    void (^responseBlock)(NSError *);
    
    NSInteger   bytesRead;
    
    NSString    *currentCommand;
    
    NSString    *activityStatus;
}

@property (assign) BOOL shouldCancelActivity;
@property (assign) BOOL debugOutput;
@property (retain) NSMutableData *responseBytes;

- (void)setActivityStatusAndNotifiy:(NSString *)value;

- (void)connectUsingBlock:(LBResponseBlock)block;

- (BOOL)isConnected;

- (NSString*) responseAsString;

// for subclassers
- (void)callBlockWithError:(NSError*)err;
- (void)callBlockWithError:(NSError*)err killReadBlock:(BOOL)killReadBlock;
- (NSString*)firstLineOfData:(NSData*)data;
- (NSString*)lastLineOfData:(NSData*)data;
- (BOOL)endOfData:(NSData*)data isEqualTo:(NSString*)string;
- (NSString*)singleLineResponseFromData:(NSData*)data;

- (void)sendCommand:(NSString*)command withArgument:(NSString*)arg;
- (void)sendCommand:(NSString*)command withArgument:(NSString*)arg readBlock:(void (^)(LBTCPReader *))block;

- (void)sendData:(NSData*)data readBlock:(void (^)(LBTCPReader *))block;

- (void)appendDataFromReader:(LBTCPReader*)reader;

@end
