/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "LBAccountTests.h"

@implementation LBCoreAccountTests

@synthesize accountTestInfo;

- (void)setUp {
	accountTestInfo = [NSMutableDictionary dictionary];
	// FIXME: jasonrm - I'm not sure if a retain is really needed here.
	[accountTestInfo retain];

	[accountTestInfo setObject:@"Aefooci7se6ooy@lettersapp.com" forKey:@"username"];
	[accountTestInfo setObject:@"wuree2Ei9Tu5ie"			forKey:@"password"];

	[accountTestInfo setObject:@"Aefooci7se6ooy@lettersapp.com" forKey:@"fromAddress"];

	[accountTestInfo setObject:@"imap.pool.lettersapp.com" forKey:@"imapServer"];
	[accountTestInfo setObject:[NSNumber numberWithInt:993] forKey:@"imapPort"];
	[accountTestInfo setObject:@"smtp.pool.lettersapp.com" forKey:@"smtpServer"];

	[accountTestInfo setObject:[NSNumber numberWithInt:CONNECTION_TYPE_TLS] forKey:@"authType"];
	[accountTestInfo setObject:[NSNumber numberWithInt:YES] forKey:@"isActive"];
	[accountTestInfo setObject:[NSNumber numberWithInt:IMAP_AUTH_TYPE_PLAIN] forKey:@"connectionType"];
}

- (void)tearDown {
	// FIXME: jasonrm - If the above retain isn't needed, then -tearDown isn't needed either.
    [accountTestInfo release];
}


- (void)testAccountWithDictionary {
	LBAccount *account = [LBAccount accountWithDictionary:accountTestInfo];
	STAssertEqualObjects([account className], @"LBAccount", @": testAccountWithDictionary - Expected class of 'LBAccount', got '%@'", [account className]);
}

- (void)testDictionaryRepresentation {
	LBAccount *account = [LBAccount accountWithDictionary:accountTestInfo];
	NSDictionary *testDict = [account dictionaryRepresentation];
	STAssertEqualObjects([testDict objectForKey:@"username"], [accountTestInfo objectForKey:@"username"], @": testDictionaryRepresentation -  username should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"password"], [accountTestInfo objectForKey:@"password"], @": testDictionaryRepresentation -  password should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"fromAddress"], [accountTestInfo objectForKey:@"fromAddress"], @": testDictionaryRepresentation -  fromAddress should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"imapServer"], [accountTestInfo objectForKey:@"imapServer"], @": testDictionaryRepresentation - imapServer should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"imapPort"], [accountTestInfo objectForKey:@"imapPort"], @": testDictionaryRepresentation - imapPort should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"smtpServer"], [accountTestInfo objectForKey:@"smtpServer"], @": testDictionaryRepresentation - smtpServer should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"authType"], [accountTestInfo objectForKey:@"authType"], @": testDictionaryRepresentation - authType should not have been modified.");
	STAssertEqualObjects([testDict objectForKey:@"isActive"], [accountTestInfo objectForKey:@"isActive"], @": testDictionaryRepresentation - isActive should not have been modified.");
}

- (void)testIsActive {
	// TODO: jasonrm - Unless the isActive switch becomes more complex than a synthesized varible, this is a rather silly test.
	LBAccount *account = [LBAccount accountWithDictionary:accountTestInfo];
    STAssertEquals(YES, [account isActive], nil);
    account.isActive = NO;
    STAssertEquals(NO, [account isActive], nil);
    account.isActive = YES;
	STAssertEquals(YES, [account isActive], nil);
}


@end
