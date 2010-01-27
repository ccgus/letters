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
 * FOR ANY DIRELB, INDIRELB, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRALB, STRILB
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "LBAccount.h"
#import "LBServer.h"

@implementation LBAccount

@synthesize username;
@synthesize password;
@synthesize imapServer;
@synthesize fromAddress;
@synthesize authType;
@synthesize imapPort;
@synthesize connectionType;
@synthesize smtpServer;
@synthesize isActive;

- (id) init {
	self = [super init];
	if (self != nil) {
		imapPort = 993;
	}
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [username release];
    [password release];
    [imapServer release];
    [smtpServer release];
    [fromAddress release];
    
    [super dealloc];
}

- (LBServer*) server {
    
    if (!server) {
        
        NSString *cacheFolder = [@"~/Library/Letters/" stringByExpandingTildeInPath];
        
        server = [[LBServer alloc] initWithAccount:self usingCacheFolder:[NSURL fileURLWithPath:cacheFolder isDirectory:YES]];
    }
    
    return server;
}


+ (id) accountWithDictionary:(NSDictionary*)d {
    
    LBAccount *acct = [[[self alloc] init] autorelease];
    
    if ([d objectForKey:@"username"]) {
        acct.username = [d objectForKey:@"username"];
    }
    
    if ([d objectForKey:@"password"]) {
        acct.password = [d objectForKey:@"password"];
    }
    
    if ([d objectForKey:@"imapServer"]) {
        acct.imapServer = [d objectForKey:@"imapServer"];
    }
    
    if ([d objectForKey:@"fromAddress"]) {
        acct.fromAddress = [d objectForKey:@"fromAddress"];
    }
    
    if ([d objectForKey:@"authType"]) {
        acct.authType = [[d objectForKey:@"username"] intValue];
    }
    
    if ([d objectForKey:@"imapPort"]) {
        acct.imapPort = [[d objectForKey:@"imapPort"] intValue];
    }
    
    if ([d objectForKey:@"isActive"]) {
        acct.isActive = [[d objectForKey:@"isActive"] boolValue];
    }
    
    if ([d objectForKey:@"connectionType"]) {
        acct.connectionType = [[d objectForKey:@"connectionType"] intValue];
    }
    
    if ([d objectForKey:@"smtpServer"]) {
        acct.smtpServer = [d objectForKey:@"smtpServer"];
    }
    
    return acct;
}

- (NSDictionary*) dictionaryRepresentation {

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    [d setObject:username ? username : @"" forKey:@"username"];
    [d setObject:password ? password : @"" forKey:@"password"];
    
    [d setObject:fromAddress ? fromAddress : @"" forKey:@"fromAddress"];
    
    [d setObject:imapServer ? imapServer : @"" forKey:@"imapServer"];
    [d setObject:smtpServer ? smtpServer : @"" forKey:@"smtpServer"];
    
    [d setObject:[NSNumber numberWithInt:authType] forKey:@"authType"];
    [d setObject:[NSNumber numberWithInt:imapPort] forKey:@"imapPort"];
    [d setObject:[NSNumber numberWithInt:isActive] forKey:@"isActive"];
    
    [d setObject:[NSNumber numberWithInt:connectionType] forKey:@"connectionType"];
    
    return d;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ (%@@%@)", [super description], username, imapServer];
}

@end
