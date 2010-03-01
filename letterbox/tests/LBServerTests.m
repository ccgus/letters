//
//  LBServerTests.m
//  LetterBox
//
//  Created by August Mueller on 2/28/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBServerTests.h"
#import "LBAccount.h"
#import "LBTestIMAPServer.h"
#import "LBServer.h"

#define debug NSLog

@implementation LBServerTests

- (void)addObserverForName:(NSString*)notifName usingBlock:(void (^)(NSNotification *))block {
    
    [[NSNotificationCenter defaultCenter] addObserverForName:notifName
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:block];
}

- (void)xtestDeleteAndExpunge {
    
    #warning GUS YOU ARE WORKING ON THIS
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"LBServerTestDelete.plist"];
    
    LBInitTest();
    
    __block BOOL gotDeleteNotification       = NO;
    __block BOOL gotFlagsUpdatedNotification = NO;
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        [self addObserverForName:LBServerMessageDeletedNotification usingBlock:^(NSNotification *arg1) {
            gotDeleteNotification = YES;
        }];
        
        LBAccount *account  = [LBTestIMAPServer testAccount];
        LBServer *server    = [account server];
        
        [server connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [server deleteMessages:@"1" withBlock:^(NSError *err) {
                
                LBAssertTrue(gotDeleteNotification, @"Delete notification");
                
                LBTestError(err, @"Got an error delete!");
                
                [server expungeWithBlock:^(NSError *err) {
                    
                    LBEndTest();
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}

@end
