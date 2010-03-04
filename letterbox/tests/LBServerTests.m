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
        
        [self addObserverForName:LBServerMessageDeletedNotification usingBlock:^(NSNotification *note) {
            gotDeleteNotification = ([note object] == server && [[[note userInfo] objectForKey:@"uid"] isEqualToString:@"98797"]);
            
            NSArray *messages = [server messageListForPath:@"INBOX"];
            
            LBMessage *firstMessage = [messages objectAtIndex:0];
            
            LBAssertTrue([firstMessage deletedFlag], @"checking the deleted flag for the first message yo");
        }];
        
        [server connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
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
        }];
    });
    
    LBWaitForFinish();
}




- (void) testCapabilityAndMove {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"LBServerTestCapabilityAndMove.plist"];
    
    LBInitTest();
    
    __block BOOL gotDeleteNotification = NO;
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account  = [LBTestIMAPServer testAccount];
        LBServer *server    = [account server];
        
        #warning ummmmmmmmmmmmmmmmmm check for a message moved notif?
        [self addObserverForName:LBServerMessageDeletedNotification usingBlock:^(NSNotification *note) {
            debug(@"noooooooooootificionat");
            gotDeleteNotification = ([note object] == server && [[[note userInfo] objectForKey:@"uid"] isEqualToString:@"390"]);
        }];
        
        debug(@"connecting");
        [server connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            debug(@"finding caps");
            [server findCapabilityWithBlock:^(NSError *err) {
                
                LBAssertTrue(server.capabilityUIDPlus, @"Checking capabilityUIDPlus");
                
                NSArray *uidArray = [NSArray arrayWithObject:@"390"];
                
                debug(@"ok, going to move.");
                
                [server moveMessagesWithUIDs:uidArray
                                   inMailbox:@"INBOX.acorn"
                                   toMailbox:@"INBOX"
                                   withBlock:^(NSError *err)
                {
                    #warning should this be a move notification?
                    
                    LBAssertTrue(gotDeleteNotification, @"Did not get delete notification");
                    
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








