//
//  LBIMAPConnectionTests.m
//  LetterBox
//
//  Created by Jason McNeil on 1/25/10.
//  Copyright 2010 Jason R. McNeil. All rights reserved.
//

#import "LBIMAPConnectionTests.h"


@implementation LBIMAPConnectionTests

@synthesize accountTestInfo;

- (void)setUp {
	accountTestInfo = [NSMutableDictionary dictionary];
    
	[accountTestInfo setObject:@"letters.app@jasonrm.net" forKey:@"username"];
	[accountTestInfo setObject:@"letters.app" forKey:@"password"];
    
	[accountTestInfo setObject:@"letters.app@jasonrm.net" forKey:@"fromAddress"];
    
	[accountTestInfo setObject:@"jasonrm.net" forKey:@"imapServer"];
	[accountTestInfo setObject:[NSNumber numberWithInt:993] forKey:@"imapPort"];
	[accountTestInfo setObject:@"jasonrm.net" forKey:@"smtpServer"];
    
	[accountTestInfo setObject:[NSNumber numberWithInt:CONNECTION_TYPE_TLS] forKey:@"authType"];
	[accountTestInfo setObject:[NSNumber numberWithInt:YES] forKey:@"isActive"];
	[accountTestInfo setObject:[NSNumber numberWithInt:IMAP_AUTH_TYPE_PLAIN] forKey:@"connectionType"];   
}

- (void)testConnectDisconnect {
    NSString *cacheFolder   = [@"~/Library/Letters/" stringByExpandingTildeInPath];
    LBAccount *account      = [LBAccount accountWithDictionary:accountTestInfo];
//    LBServer *server        = [[LBServer alloc] initWithAccount:account usingCacheFolder:[NSURL fileURLWithPath:cacheFolder isDirectory:YES]];

    LBIMAPConnection *imapConnection = [[[LBIMAPConnection alloc] init] autorelease];

    NSError *err = nil;
//    [imapConnection connectWithAccount:account error:&err];
//    [imapConnection disconnect];
    
    //STAssertEquals(1, nil, @"%@", [imapConnection connectWithAccount:account error:&err]);

    //[server checkInIMAPConnection:imapConnection];
    //    NSArray *list = [imapConnection subscribedFolderNames:&err];
    //STAssertEqualObjects(list, nil, @"%@", list);
}

@end
