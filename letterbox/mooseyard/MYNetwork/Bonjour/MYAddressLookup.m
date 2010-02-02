//
//  MYAddressLookup.m
//  MYNetwork
//
//  Created by Jens Alfke on 4/24/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYAddressLookup.h"
#import "MYBonjourService.h"
#import "IPAddress.h"
#import "ExceptionUtils.h"
#import "Test.h"
#import "Logging.h"
#import <dns_sd.h>


@interface MYAddressLookup ()
@property (copy) NSString *hostname;
@end


@implementation MYAddressLookup

- (id) initWithHostname: (NSString*)hostname
{
    self = [super init];
    if (self != nil) {
        if (!hostname) {
            [self release];
            return nil;
        }
        _hostname = [hostname copy];
        _addresses = [[NSMutableSet alloc] init];
    }
    return self;
}


- (id) _initWithBonjourService: (MYBonjourService*)service {
    self = [super init];
    if (self) {
        _service = [service retain];
        _addresses = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [_hostname release];
    [_addresses release];
    [_service release];
    [super dealloc];
}


- (NSString*) description
{
    return $sprintf(@"%@[%@]", self.class,_hostname);
}


@synthesize hostname=_hostname, port=_port, interfaceIndex=_interfaceIndex, addresses=_addresses;


- (NSTimeInterval) timeToLive {
    return MAX(0.0, _expires - CFAbsoluteTimeGetCurrent());
}


- (BOOL) start {
    if (_hostname) {
        return [super start];
    } else {
        // Service doesn't know its hostname yet; wait till it does:
        LogTo(DNS,@"MYAddressLookup requesting hostname of %@ ...", _service);
        Assert(_service);
        return [_service start];
    }
}


// Called by my _service's gotResponse method:
- (void) _serviceGotResponse {
    Assert(_service);
    DNSServiceErrorType err = _service.error;
    if (err) {
        [self cancel];
        self.error = err;
    } else {
        NSString *hostname = _service.hostname;
        UInt16 port = _service.port;
        if (port!=_port || !$equal(hostname,_hostname)) {
            self.hostname = hostname;
            self.port = port;
            if (_hostname)
                [self start];
        }
    }
}


- (void) priv_resolvedAddress: (const struct sockaddr*)sockaddr
                          ttl: (uint32_t)ttl
                        flags: (DNSServiceFlags)flags
{
    HostAddress *address = [[HostAddress alloc] initWithHostname: _hostname 
                                                        sockaddr: sockaddr
                                                            port: _port];
    if (address) {
        if (flags & kDNSServiceFlagsAdd) {
            LogTo(DNS,@"%@ got %@ [TTL = %u]", self, address, ttl);
            kvAddToSet(self, @"addresses", _addresses, address);
        } else {
            LogTo(DNS,@"%@ lost %@ [TTL = %u]", self, address, ttl);
            kvRemoveFromSet(self, @"addresses", _addresses, address);
        }
        [address release];
    }
    
    _expires = CFAbsoluteTimeGetCurrent() + ttl;
}


static void lookupCallback(DNSServiceRef                    sdRef,
                           DNSServiceFlags                  flags,
                           uint32_t                         interfaceIndex,
                           DNSServiceErrorType              errorCode,
                           const char                       *hostname,
                           const struct sockaddr            *address,
                           uint32_t                         ttl,
                           void                             *context)
{
    MYAddressLookup *lookup = context;
    @try{
        LogTo(DNS, @"lookupCallback for %s (err=%i)", hostname,errorCode);
        if (errorCode)
            [lookup setError: errorCode];
        else
            [lookup priv_resolvedAddress: address ttl: ttl flags: flags];
    }catchAndReport(@"MYDNSLookup query callback");
    [lookup gotResponse: errorCode];
}


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    Assert(_hostname);
    kvSetSet(self, @"addresses", _addresses, nil);
    return DNSServiceGetAddrInfo(sdRefPtr,
                                 kDNSServiceFlagsShareConnection,
                                 _interfaceIndex, 
                                 kDNSServiceProtocol_IPv4,
                                 _hostname.UTF8String,
                                 &lookupCallback, self);
}


@end



TestCase(MYDNSLookup) {
    EnableLogTo(Bonjour,YES);
    EnableLogTo(DNS,YES);
    [NSRunLoop currentRunLoop]; // create runloop

    MYAddressLookup *lookup = [[MYAddressLookup alloc] initWithHostname: @"www.apple.com" port: 80];
    [lookup start];
    
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 10]];
    [lookup release];
}    


/*
 Copyright (c) 2009, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
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
