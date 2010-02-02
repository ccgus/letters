//
//  BLIPEndpoint.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/14/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "TCPEndpoint.h"
#import "Test.h"
#import "CollectionUtils.h"
#import "ExceptionUtils.h"
#import <Security/Security.h>


NSString* const kTCPPropertySSLClientSideAuthentication = @"kTCPPropertySSLClientSideAuthentication";


@implementation TCPEndpoint


- (void) dealloc
{
    [_sslProperties release];
    [super dealloc];
}


- (NSMutableDictionary*) SSLProperties {return _sslProperties;}

- (void) setSSLProperties: (NSMutableDictionary*)props
{
    if( props != _sslProperties ) {
        [_sslProperties release];
        _sslProperties = [props mutableCopy];
    }
}

- (void) setSSLProperty: (id)value forKey: (NSString*)key
{
    if( value ) {
        if( ! _sslProperties )
            _sslProperties = [[NSMutableDictionary alloc] init];
        [_sslProperties setObject: value forKey: key];
    } else
        [_sslProperties removeObjectForKey: key];
}

- (NSString*) securityLevel                 {return [_sslProperties objectForKey: (id)kCFStreamSSLLevel];}
- (void) setSecurityLevel: (NSString*)level {[self setSSLProperty: level forKey: (id)kCFStreamSSLLevel];}

- (void) setPeerToPeerIdentity: (SecIdentityRef)identity {
    Assert(identity);
    self.SSLProperties = $mdict(
             {(id)kCFStreamSSLLevel, NSStreamSocketSecurityLevelTLSv1},
             {kTCPPropertySSLCertificates, $array((id)identity)},
             {kTCPPropertySSLAllowsAnyRoot, $true},
             {kTCPPropertySSLPeerName, [NSNull null]},
             {kTCPPropertySSLClientSideAuthentication, $object(kTCPAlwaysAuthenticate)});
}

- (void) tellDelegate: (SEL)selector withObject: (id)param
{
    if( [_delegate respondsToSelector: selector] ) {
        @try{
            [_delegate performSelector: selector withObject: self withObject: param];
        }catchAndReport(@"%@ delegate",self.class);
    }
}


@end


/*
 Copyright (c) 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
