//
//  LBIMAPConnectionTests.m
//  LetterBox
//
//  Created by August Mueller on 2/21/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBIMAPConnectionTests.h"
#import "LBIMAPConnection.h"
#import "LBAccount.h"
#import "LBTestIMAPServer.h"

#define debug NSLog


@implementation LBIMAPConnectionTests

- (void)testLoginLogout {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testLoginLogout.plist"];
    
    LBInitTest();
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBIMAPConnection *conn = [[[LBIMAPConnection alloc] initWithAccount:[LBTestIMAPServer testAccount]] autorelease];
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn logoutWithBlock:^(NSError *err) {
                
                debug(@"logged out!");
                
                LBTestError(err, @"Got an error trying to log out!");
                
                [conn close];
                
                LBEndTest();
            }];
        }];
    });
    
    LBWaitForFinish();
}
- (void)testLoginFail {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testLoginFail.plist"];
    
    LBInitTest();
    
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBIMAPConnection *conn = [[[LBIMAPConnection alloc] initWithAccount:[LBTestIMAPServer testAccount]] autorelease];
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn loginWithBlock:^(NSError *err) {
                
                LBAssertTrue(err != nil, @"We shouldn't have been able to log in.");
                
                [conn close];
                
                LBEndTest();
            }];
        }];
    });
    
    LBWaitForFinish();
}


- (void)testMobileMeSelect {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testMobileMeSelect.plist"];
    
    LBInitTest();
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account      = [LBTestIMAPServer testAccount];
        LBIMAPConnection *conn  = [[[LBIMAPConnection alloc] initWithAccount:account] autorelease];
        
        conn.debugOutput = YES;
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn loginWithBlock:^(NSError *err) {
                
                LBTestError(err, @"Got an error trying to login!");
                
                [conn selectMailbox:@"Mailbox With Spaces" block:^(NSError *err) {
                    
                    LBTestError(err, @"Got an error trying to select!");
                    
                    [conn logoutWithBlock:^(NSError *err) {
                        
                        LBTestError(err, @"Got an error trying to log out!");
                        
                        [conn close];
                        
                        LBEndTest();
                    }];
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}

- (void)testDeleteAndExpunge {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testDeleteAndExpunge.plist"];
    
    LBInitTest();
    
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account      = [LBTestIMAPServer testAccount];
        LBIMAPConnection *conn  = [[[LBIMAPConnection alloc] initWithAccount:account] autorelease];
        
        conn.debugOutput = YES;
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn loginWithBlock:^(NSError *err) {
                
                LBTestError(err, @"Got an error trying to login!");
                
                [conn selectMailbox:@"INBOX" block:^(NSError *err) {
                    
                    LBTestError(err, @"Got an error trying to select!");
                    
                    // delete the first message.
                    [conn deleteMessages:@"1" withBlock:^(NSError *err) {
                        
                        LBTestError(err, @"delete the first message.");
                        
                        [conn expungeWithBlock:^(NSError *err) {
                            
                            LBTestError(err, @"expunge");
                            
                            [conn close];
                            
                            LBEndTest();
                        }];
                    }];
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}







- (void)testListSubscriptions {
    
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testListSubscriptions.plist"];
    
    LBInitTest();
    
    // this needs to run on the main loop
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account      = [LBTestIMAPServer testAccount];
        LBIMAPConnection *conn  = [[[LBIMAPConnection alloc] initWithAccount:account] autorelease];
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn loginWithBlock:^(NSError *err) {
                LBTestError(err, @"Got an error trying to login!");
                
                [conn listSubscribedMailboxesWithBock:^(NSError *err) {
                    LBTestError(err, @"Could not list mailboxes!");
                    
                    NSArray *mailboxes = [conn fetchedMailboxes];
                    
                    LBAssertTrue([mailboxes count] > 0, @"Could not find any mailboxes");
                    
                    BOOL foundINBOX = NO;
                    BOOL foundDeletedMessages = NO;
                    
                    for (NSDictionary *box in mailboxes) {
                        foundINBOX = foundINBOX || [[box objectForKey:@"mailboxName"] isEqualToString:@"INBOX"];
                        foundDeletedMessages = foundDeletedMessages || [[box objectForKey:@"mailboxName"] isEqualToString:@"INBOX.Deleted Messages"];
                    }
                    
                    LBAssertTrue(foundINBOX, @"Could not find the inbox");
                    LBAssertTrue(foundDeletedMessages, @"Could not find the deleted messages");
                    
                    debug(@"logging out now");
                    
                    [conn logoutWithBlock:^(NSError *err) {
                        debug(@"all done!");
                        LBTestError(err, @"Got an error trying to log out!");
                        
                        [conn close];
                        
                        LBEndTest();
                    }];
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}

- (void)testBadLSUB {
    
    [[LBTestIMAPServer sharedIMAPServer] runScript:@"testBadLSUB.plist"];
    
    LBInitTest();
    
    dispatch_async(dispatch_get_main_queue(),^ {
        
        LBAccount *account      = [LBTestIMAPServer testAccount];
        LBIMAPConnection *conn  = [[[LBIMAPConnection alloc] initWithAccount:account] autorelease];
        
        [conn connectUsingBlock:^(NSError *err) {
            
            LBTestError(err, @"Got an error trying to connect!");
            
            [conn loginWithBlock:^(NSError *err) {
                LBTestError(err, @"Got an error trying to login!");
                
                [conn listSubscribedMailboxesWithBock:^(NSError *err) {
                    LBAssertTrue(err != nil, @"Should have gotten an error!");
                    
                    [conn logoutWithBlock:^(NSError *err) {
                        
                        LBTestError(err, @"Got an error trying to log out!");
                        
                        [conn close];
                        
                        LBEndTest();
                    }];
                }];
            }];
        }];
    });
    
    LBWaitForFinish();
}

@end
