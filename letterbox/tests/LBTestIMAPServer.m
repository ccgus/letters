//
//  LBTestIMAPServer.m
//  LetterBox
//
//  Created by August Mueller on 2/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBTestIMAPServer.h"
#import "LBTCPConnection.h"
#import "TCPWriter.h"
#import "LBNSStringAdditions.h"

#define debug NSLog

@implementation LBTestIMAPServer

+ (id)sharedIMAPServer {
    
    static LBTestIMAPServer *me = nil;
    
    if (!me) {
        me = [[self alloc] init];
    }
    
    return me;
}

- (NSMutableArray*)fixNewlinesInArray:(NSArray*)ar {
    NSMutableArray *ret = [NSMutableArray array];
    
    for (NSString *entry in ar) {
        
        // remove the line endings
        entry = [entry stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        entry = [entry stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        // replace occurances of the string "\r\n", with an actual crlf
        entry = [entry stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\r\n"];
        
        [ret addObject:entry];
    }
    
    return ret;
}

+ (LBAccount*)testAccount {
    
    LBAccount *acct = [[[LBAccount alloc] init] autorelease];
    [acct setUsername:@"user"];
    [acct setPassword:@"password"];
    [acct setImapServer:@"localhost"];
    [acct setImapPort:1430];
    [acct setIsActive:YES];
    [acct setImapTLS:NO];
    
    [[acct server] clearCache];
    
    return acct;
}

+ (LBAccount*)realAccount {
    
    // oh what to do here?
    LBAccount *acct = [[[LBAccount alloc] init] autorelease];
    [acct setUsername:@"gus"];
    [acct setPassword:@"password"];
    [acct setImapServer:@"ubuntu.local"];
    [acct setImapPort:143];
    [acct setIsActive:YES];
    [acct setImapTLS:NO];
    
    
    [[acct server] clearCache];
    
    return acct;
}



- (NSString*)pathToTestScript:(NSString*)scriptName {
    NSString *myFilePath = [NSString stringWithUTF8String:__FILE__];
    NSString *parentDir = [[myFilePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    NSString *testDir   = [[parentDir stringByAppendingPathComponent:@"tests"] stringByAppendingPathComponent:@"testscripts"];
    NSString *taskPath  = [testDir stringByAppendingPathComponent:scriptName];
    
    return taskPath;
}

- (void)runScript:(NSString*)pathToScript {
    
    if (!listener) {
        
        dispatch_sync(dispatch_get_main_queue(),^ {
        
            listener = [[TCPListener alloc] initWithPort:1430];
            
            [listener setConnectionClass:[LBTCPConnection class]];
            
            NSError *err = 0x00;
            if (![listener open:&err]) {
                NSLog(@"Got an error opening the listener: %@", err);
                return;
            }
            
            [listener setDelegate:self];
        });
        
    }
    
    pathToScript = [self pathToTestScript:pathToScript];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:pathToScript];
    
    assert(d);
    
    [acceptList   release];
    [responseList release];
    
    acceptList      = [[self fixNewlinesInArray:[d objectForKey:@"accept"]] retain];
    responseList    = [[self fixNewlinesInArray:[d objectForKey:@"send"]] retain];
}

- (void)sendResponse:(LBTCPReader *)reader {
    
    if (![responseList count]) {
        NSLog(@"Out of things to send!");
        assert(false);
        return;
    }
    
    NSString *res = [responseList objectAtIndex:0];
    
    [(TCPWriter *)[reader writer] writeData:[res utf8Data]];
    
    [responseList removeObjectAtIndex:0];
}

- (void)assertAcceptedString:(NSString*)got {
    
    if (![acceptList count]) {
        NSLog(@"Out of things to accept!");
        assert(false);
        return;
    }
    
    NSString *expected = [acceptList objectAtIndex:0];
    
    if (![expected isEqualToString:got]) {
        debug(@"expected: %@", expected);
        debug(@"got:      %@", got);
        assert(false);
    }
    
    [acceptList removeObjectAtIndex:0];
    
}

- (void)listener:(TCPListener*)listener didAcceptConnection:(LBTCPConnection*)connection {
    
    [(LBTCPReader *)[connection reader] setCanReadBlock:^(LBTCPReader *reader) {
        
        if (!readString) {
            readString = [[NSMutableString stringWithString:[reader stringFromReadData]] retain];
        }
        else {
            [readString appendString:[reader stringFromReadData]];
        }
        
        if (![readString hasSuffix:@"\r\n"]) {
            // still waiting on data.
            return;
        }
        
        [self assertAcceptedString:readString];
        [self sendResponse:reader];
        
        [readString release];
        readString = nil;
        
    }];
    
    // send our first "* OK whatever" message
    [self sendResponse:(LBTCPReader*)[connection reader]];
}

@end
