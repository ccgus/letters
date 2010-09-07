#import "LBSMTPConnection.h"
#import "TCP_Internal.h"
#import "LBAccount.h"
#import "IPAddress.h"
#import "LetterBoxUtilities.h"
#import "LBMessage.h"

static NSString *LBSMTPHELLO    = @"HELO";
static NSString *LBSMTPEHLO     = @"EHLO";
static NSString *LBSMTPMAILFROM = @"MAIL FROM:";
static NSString *LBSMTPRCPTTO   = @"RCPT TO:";
static NSString *LBSMTPDATA     = @"DATA";

@implementation LBSMTPConnection


- (id)initWithAccount:(LBAccount*)anAccount {
    
    // FIXME: add a "smtp port" option
    IPAddress *addr = [IPAddress addressWithHostname:[anAccount smtpServer] port:25];
    self = [self initToAddress:addr];
    
    if (self != nil) {
        
        [self setAccount:anAccount];
        
        // FIXME: add an option for smtp + ssl
        
        /*
        
        if ([account imapTLS]) {
            
            NSMutableDictionary *sslProps = [NSMutableDictionary dictionary];
            
            [sslProps setObject:[NSNumber numberWithBool:YES] forKey:(id)kTCPPropertySSLAllowsAnyRoot];
            [sslProps setObject:[NSNull null] forKey:(id)kCFStreamSSLPeerName];
            [sslProps setObject:NSStreamSocketSecurityLevelTLSv1 forKey:(id)kCFStreamSSLLevel];
            
            [self setSSLProperties:sslProps];
        }
        */
    }
    
    return self;
}



- (void)connectUsingBlock:(LBResponseBlock)block {
    
    [(LBTCPReader*)[self reader] setCanReadBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *res = [[self responseBytes] lbFirstLine];
        if (!res) {
            // haven't gotten our crlf yet.
            return;
        }
        
        NSError *err = nil;
        
        if (![res hasPrefix:@"220 "]) {
            NSString *junk  = [NSString stringWithFormat:@"Could not connect: '%@'", [self responseAsString]];
            LBQuickError(&err, LBCONNECTING, 0, junk);
        }
        
        if (err) {
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        NSString *serverName = [[self address] hostname];
        
        // FIXME: we should really use esmtp here, and find out the server capibilities and such.
        //[self sendCommand:LBSMTPEHLO withArgument:serverName readBlock:^(LBTCPReader *arg1) {
        [self sendCommand:LBSMTPHELLO withArgument:serverName readBlock:^(LBTCPReader *arg1) {
            
            [self appendDataFromReader:reader];
            
            NSString *res = [[self responseBytes] lbFirstLine];
            
            // check to see if we have our line, with a crlf
            if (!res) {
                return;
            }
            
            NSError *err = nil;
            
            if (![res hasPrefix:@"250 "]) {
                NSString *junk  = [NSString stringWithFormat:@"Could not connect: '%@'", [self responseAsString]];
                LBQuickError(&err, LBSMTPHELLO, 0, junk);
            }
            
            [self callBlockWithError:err killReadBlock:YES];
        }];
    }];
    
    [super connectUsingBlock:block];
}

- (void)sendMessage:(LBMessage*)message block:(LBResponseBlock)block {
    
    LBAssert([message to]);
    LBAssert([message sender]);
    LBAssert([message messageBody]);
    
    responseBlock = [block copy];
    
    NSString *to   = [NSString stringWithFormat:@"%@<%@>", LBSMTPRCPTTO, [message to]];
    NSString *from = [NSString stringWithFormat:@"%@<%@>", LBSMTPMAILFROM, [message sender]];
    
    [self sendCommand:from withArgument:nil readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *res = [[self responseBytes] lbFirstLine];
        if (!res) {
            return;
        }
        
        NSError *err = nil;
        if (![res hasPrefix:@"250 "]) {
            NSString *junk  = [NSString stringWithFormat:@"Could not email: '%@'", [self responseAsString]];
            LBQuickError(&err, LBSMTPMAILFROM, 0, junk);
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        [self sendCommand:to withArgument:nil readBlock:^(LBTCPReader *reader) {
            
            [self appendDataFromReader:reader];
            
            NSString *res = [[self responseBytes] lbFirstLine];
            if (!res) {
                return;
            }
            
            NSError *err = nil;
            if (![res hasPrefix:@"250 "]) {
                NSString *junk  = [NSString stringWithFormat:@"Could not email: '%@'", [self responseAsString]];
                LBQuickError(&err, LBSMTPRCPTTO, 0, junk);
                [self callBlockWithError:err killReadBlock:YES];
                return;
            }
            
            [self sendCommand:LBSMTPDATA withArgument:nil readBlock:^(LBTCPReader *reader) {
                
                [self appendDataFromReader:reader];
                
                NSString *res = [[self responseBytes] lbFirstLine];
                if (!res) {
                    return;
                }
                
                NSError *err = nil;
                if (![res hasPrefix:@"354 "]) {
                    NSString *junk  = [NSString stringWithFormat:@"Could not set data: '%@'", [self responseAsString]];
                    LBQuickError(&err, LBSMTPDATA, 0, junk);
                    [self callBlockWithError:err killReadBlock:YES];
                    return;
                }
                
                [self sendData:[message SMTPData] readBlock:^(LBTCPReader *reader) {
                    [self appendDataFromReader:reader];
                    
                    NSString *res = [[self responseBytes] lbFirstLine];
                    if (!res) {
                        return;
                    }
                    
                    NSError *err = nil;
                    if (![res hasPrefix:@"250 "]) {
                        NSString *junk  = [NSString stringWithFormat:@"Could not send message: '%@'", [self responseAsString]];
                        LBQuickError(&err, LBSMTPDATA, 0, junk);
                    }
                    
                    [self callBlockWithError:err killReadBlock:YES];
                }];
            }];
        }];
    }];
}

/*
- (void) test {
    
    [self setDebugOutput:[LBPrefs boolForKey:@"debugIMAPMessages"]];
    
    [self connectUsingBlock:^(NSError *error) {
        
        if (error) {
            // FIXME: show a warning or something?
            NSLog(@"error: %@", error);
            return;
        }
        
        
        NSString *messageId = [NSString stringWithFormat:@"Message-ID: %@\r\n", LBUUIDString()];
        NSString *mailer    = @"X-Mailer: Letterbox\r\n";
        NSString *subject   = @"Subject: Hello Gus!";
        NSString *message   = @"Hello there good sir, how are you?";
        
        NSString *body = [NSString stringWithFormat:@"%@%@%@\r\n", messageId, mailer, subject, message];
        
        [self sendMessage:body to:@"gus@ubuntu.localdomain" from:@"gus@ubuntu.localdomain" block:^(NSError *err) {
            if (err) {
                debug(@"well, crap.  Our message didn't send!");
                debug(@"err: %@", err);
                return;
            }
            
            debug(@"message sent!");
        }];
    }];
}
*/

@end
