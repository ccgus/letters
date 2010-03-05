//
//  LBServerTests.m
//  LetterBox
//
//  Created by August Mueller on 2/28/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBServerTests.h"
#import "LBAccount.h"
#import "LBMessage.h"
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

- (void) testDeleteAndExpunge {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"LBServerTestDelete.plist"];
    
    LBInitTest();
    
    __block BOOL gotDeleteNotification       = NO;
    //__block BOOL gotFlagsUpdatedNotification = NO;
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account  = [LBTestIMAPServer testAccount];
        LBServer *server    = [account server];
        
        NSArray *messages       = [server messageListForPath:@"INBOX"];
        LBMessage *firstMessage = [messages objectAtIndex:0];
        
        [server connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [server updateMessagesInMailbox:@"INBOX" withBlock:^(NSError *err) {
                
                NSArray *messages = [server messageListForPath:@"INBOX"];
                
                LBAssertTrue([messages count] == 2, @"message list should have been two");
                
                [server deleteMessage:firstMessage withBlock:^(NSError *err) {
                    
                    LBAssertTrue([[firstMessage serverUID]  isEqualToString:@"98797"], @"updated uid");
                    LBAssertTrue([firstMessage deletedFlag], @"checking the deleted flag for the first message yo");
                    LBAssertTrue(gotDeleteNotification, @"Did not get delete notification");
                    
                    LBTestError(err, @"Got an error delete!");
                    
                    debug(@"yay?");
                    
                    [server expungeWithBlock:^(NSError *err) {
                        LBEndTest();
                    }];
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}




- (void) testCapabilityAndMove {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"LBServerTestCapabilityAndMove.plist"];
    
    LBInitTest();
    
    __block BOOL gotMoveNotification = NO;
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account  = [LBTestIMAPServer testAccount];
        LBServer *server    = [account server];
        
        #warning ummmmmmmmmmmmmmmmmm check for a message moved notif?
        [self addObserverForName:LBServerMessageDeletedNotification usingBlock:^(NSNotification *note) {
            debug(@"noooooooooootificionat");
            gotMoveNotification = ([note object] == server && [[[note userInfo] objectForKey:@"uid"] isEqualToString:@"390"]);
        }];
        
        debug(@"connecting");
        [server connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            debug(@"finding caps");
            [server findCapabilityWithBlock:^(NSError *err) {
                
                LBAssertTrue(server.capabilityUIDPlus, @"Checking capabilityUIDPlus");
                
                LBMessage *message = [[[LBMessage alloc] init] autorelease];
                
                [message setServerUID:@"390"];
                [message setMailbox:@"INBOX.acorn"];
                
                [server moveMessage:message toMailbox:@"INBOX" withBlock:^(NSError *err) {
                    #warning should this be a move notification?
                    
                    LBAssertTrue(gotMoveNotification, @"gotMoveNotification is false");
                    
                    LBTestError(err, @"Got an error delete!");
                    
                    debug(@"yay?");
                    
                    LBEndTest();
                }];
                
            }];
            
            /*
            
            
            [server updateMessagesInMailbox:@"INBOX" withBlock:^(NSError *err) {
                
                NSArray *messages = [server messageListForPath:@"INBOX"];
                
                LBAssertTrue([messages count] == 2, @"message list should have been two");
                
                LBMessage *firstMessage = [messages objectAtIndex:0];
                
                [server deleteMessageWithUID:[firstMessage serverUID] inMailbox:@"INBOX" withBlock:^(NSError *err) {
                    
                    LBAssertTrue(gotDeleteNotification, @"Did not get delete notification");
                    
                    LBTestError(err, @"Got an error delete!");
                    
                    debug(@"yay?");
                    
                    [server expungeWithBlock:^(NSError *err) {
                        LBEndTest();
                    }];
                }];
            }];
            */
        }];
    });
    
    LBWaitForFinish();
}

@end








