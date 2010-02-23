//
//  LBTCPConnection.m
//  LetterBox
//
//  Created by August Mueller on 2/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBTCPConnection.h"
#import "LBTCPReader.h"
#import "LBAccount.h"

#import "TCP_Internal.h"
#import "IPAddress.h"

NSString *LBCONNECTING = @"THISSTRINGDOESN'TMATTER";

@implementation LBTCPConnection
@synthesize shouldCancelActivity;
@synthesize responseBytes;
@synthesize debugOutput;
@synthesize account;

- (void)dealloc {
    
    [responseBytes release];
    [activityStatus release];
    [account release];
    
    [super dealloc];
}


// yes, I know we're not an imap class- but this guy does something really simple.  I should probably rename it.
-(Class) readerClass   {return [LBTCPReader class];}

- (void)sendCommand:(NSString*)command withArgument:(NSString*)arg {
    [self sendCommand:command withArgument:arg readBlock:nil];
}

- (NSString*)modifyCommandString:(NSString*)commandString {
    return commandString;
}

- (void)sendData:(NSData*)data readBlock:(void (^)(LBTCPReader *))block {
    
    bytesRead           = 0;
    self.responseBytes  = [NSMutableData data];
    
    if (self.debugOutput) {
        NSLog(@"C: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    }
    
    [(LBTCPReader*)[self reader] setCanReadBlock:block];
    
    [[self writer] writeData:data];
}


- (void)sendCommand:(NSString*)command withArgument:(NSString*)arg readBlock:(void (^)(LBTCPReader *))block {
    
    currentCommand      = command;
    
    NSString *stringToSend = nil;
    
    if (arg) {
        stringToSend = [NSString stringWithFormat:@"%@ %@\r\n", command, arg];
    }
    else {
        stringToSend = [NSString stringWithFormat:@"%@\r\n", command];
    }
    
    stringToSend = [self modifyCommandString:stringToSend];
    
    [self sendData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding] readBlock:block];
}

- (void)appendDataFromReader:(LBTCPReader*)reader {
    #define MAX_BYTES_READ 2048
    
    NSMutableData *data         = [NSMutableData dataWithLength:MAX_BYTES_READ];
    NSInteger localBytesRead    = [reader read:[data mutableBytes] maxLength:MAX_BYTES_READ];
    
    [[self responseBytes] appendBytes:[data mutableBytes] length:localBytesRead];
    
    bytesRead += localBytesRead;
    
    
    if (self.debugOutput) {
        NSString *junk = [[[NSString alloc] initWithBytes:[data bytes] length:localBytesRead encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"S: %@", junk);
    }
}

- (void)connectUsingBlock:(LBResponseBlock)block {
    
    responseBlock       = [block copy];
    
    self.delegate       = self;
    
    currentCommand      = LBCONNECTING;
    bytesRead           = 0;
    self.responseBytes  = [NSMutableData data];
    
    [self open];
}

- (void) connectionDidOpen: (TCPConnection*)connection {
    //debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert {
    //NSLog(@"** %@ authorizeSSLPeer: %@",self, [TCPEndpoint describeCert:peerCert]);
    return peerCert != nil;
}



- (void)callBlockWithError:(NSError*)err {
    [self callBlockWithError:err killReadBlock:NO];
}

- (void)callBlockWithError:(NSError*)err killReadBlock:(BOOL)killReadBlock {
    
    if (killReadBlock) {
        [(LBTCPReader*)[self reader] setCanReadBlock:nil];
    }
    
    if (responseBlock) {
        
        void (^local)(NSError *) = responseBlock;
        
        // get rid of it, because we might be reassigning it in the very block we're calling
        responseBlock = nil;
        
        dispatch_async(dispatch_get_main_queue(),^ {
            local(err);
            [local release];
        });
    }
}

- (NSString*)responseAsString {
    return [[[NSString alloc] initWithBytes:[self.responseBytes bytes] length:[self.responseBytes length] encoding:NSUTF8StringEncoding] autorelease];
}


- (BOOL)isConnected {
    return [self status] == kTCP_Open;
}

- (int) activityType {
    return 0;
}

- (void)setActivityStatusAndNotifiy:(NSString *)value {
    if (activityStatus != value) {
        
        BOOL isNew  = (value && !activityStatus);
        BOOL isOver = (!value) && activityStatus;
        
        [activityStatus release];
        activityStatus = [value retain];
        
        dispatch_async(dispatch_get_main_queue(),^ {
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self forKey:@"activity"];
            
            if (isNew) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityStartedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            else if (isOver) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityEndedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:LBActivityUpdatedNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            
        });
        
    }
}

- (NSString*) activityStatus {
    return activityStatus;
}

- (void) cancelActivity {
    shouldCancelActivity = YES;
    [self setActivityStatusAndNotifiy:NSLocalizedString(@"Canceling…", @"Canceling…")];
}


@end
