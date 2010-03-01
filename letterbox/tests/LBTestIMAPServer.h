//
//  LBTestIMAPServer.h
//  LetterBox
//
//  Created by August Mueller on 2/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPListener.h"
#import "LBAccount.h"

#import <GHUnit/GHUnit.h>

@interface LBTestIMAPServer : GHTestCase <TCPListenerDelegate> {
    TCPListener *listener;
    
    NSMutableArray *acceptList;
    NSMutableArray *responseList;
    
    NSMutableString *readString;
    
}

+ (id)sharedIMAPServer;
- (void)runScript:(NSString*)pathToScript;

+ (LBAccount*)testAccount;
+ (LBAccount*)realAccount;

@end


#define LBTestError(err, reason) { if (err) {   NSLog(@"err: %@", err);\
                                                failed = YES;\
                                                failReason = reason;\
                                                waitForFinish = NO;\
                                                return; } }

#define LBAssertTrue(b, reason) { if (!(b)) {   failed = YES;\
                                                failReason = reason;\
                                                waitForFinish = NO;\
                                                return; } }

#define LBInitTest() __block BOOL failed            = NO;\
                     __block NSString *failReason   = nil;\
                     __block BOOL waitForFinish     = YES;\
                     __block NSTask *serverTask     = nil;
                     
#define LBEndTest() waitForFinish = NO;

#define LBWaitForFinish() { while (waitForFinish) { sleep(.1); } [serverTask terminate]; [serverTask release]; GHAssertFalse(failed, failReason); }



