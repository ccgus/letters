//
//  LBTCPConnection.m
//  LetterBox
//
//  Created by August Mueller on 2/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBTCPConnection.h"
#import "LBTCPReader.h"

#import "TCP_Internal.h"
#import "IPAddress.h"


@implementation LBTCPConnection
@synthesize shouldCancelActivity;
@synthesize responseBytes;
@synthesize debugOutput;

- (void)dealloc {
    
    [responseBytes release];
    [activityStatus release];
    
    [super dealloc];
}


// yes, I know we're not an imap class- but this guy does something really simple.  I should probably rename it.
-(Class) readerClass   {return [LBTCPReader class];}

- (void) connectionDidOpen: (TCPConnection*)connection {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert {
    NSLog(@"** %@ authorizeSSLPeer: %@",self, [TCPEndpoint describeCert:peerCert]);
    return peerCert != nil;
}

- (void)canRead:(LBTCPReader*)reader {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
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
