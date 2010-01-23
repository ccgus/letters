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

#import "LBSMTP.h"
#import "LBAddress.h"
#import "LBMessage.h"
#import "LetterBoxTypes.h"

@implementation LBSMTP
- (id)initWithResource:(mailsmtp *)smtp {
    self = [super init];
    if (self) {
        _smtp = smtp;
    }
    return self;
}


- (void)connectToServer:(NSString *)server port:(unsigned int)port {
    /* first open the stream */
    int ret = mailsmtp_socket_connect([self resource], [server cStringUsingEncoding:NSUTF8StringEncoding], port);
    
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPSocketDesc);
        return;
    }
    
   // IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPSocket, LBSMTPSocketDesc);
}


- (bool)helo {
    /*  The server doesn't support esmtp, so try regular smtp */
    int ret = mailsmtp_helo([self resource]);
    
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPHelloDesc);
        return NO;
    }
    
    //IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPHello, LBSMTPHelloDesc);
    return YES; /* The server supports helo so return YES */
}


- (void)startTLS {
    //TODO Raise exception
}


- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password server:(NSString *)server {
    //TODO Raise exception
}


- (void)setFrom:(NSString *)fromAddress {
    int ret = mailsmtp_mail([self resource], [fromAddress cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPFromDesc);
        return;
    }
    
    //IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPFrom, LBSMTPFromDesc);
}


- (void)setRecipients:(id)recipients {
    NSEnumerator *objEnum = [recipients objectEnumerator];
    LBAddress *rcpt;
    while(rcpt = [objEnum nextObject]) {
        [self setRecipientAddress:[rcpt email]];
    }
}


- (void)setRecipientAddress:(NSString *)recAddress {
    int ret = mailsmtp_rcpt([self resource], [recAddress cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPRecipientsDesc);
        return;
    }
    
    //IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPRecipients, LBSMTPRecipientsDesc);
}


- (void)setData:(NSString *)data {
    NSData *dataObj = [data dataUsingEncoding:NSUTF8StringEncoding];
    int ret = mailsmtp_data([self resource]);
    
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPDataDesc);
        return;
    }
    
    //IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPData, LBSMTPDataDesc);
    ret = mailsmtp_data_message([self resource], [dataObj bytes], [dataObj length]);
    if (ret != MAILSMTP_NO_ERROR) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(LBSMTPDataDesc);
        return;
    }
    
    //IfTrue_RaiseException(ret != MAILSMTP_NO_ERROR, LBSMTPData, LBSMTPDataDesc);
}


- (mailsmtp *)resource {
    return _smtp;
}
@end
