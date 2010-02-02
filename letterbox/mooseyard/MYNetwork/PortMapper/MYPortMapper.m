//
//  MYPortMapper.m
//  MYNetwork
//
//  Created by Jens Alfke on 1/4/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYPortMapper.h"
#import "IPAddress.h"
#import "CollectionUtils.h"
#import "Logging.h"
#import "ExceptionUtils.h"

#import <dns_sd.h>


NSString* const MYPortMapperChangedNotification = @"MYPortMapperChanged";


@interface MYPortMapper ()
@property (retain) IPAddress* publicAddress, *localAddress; // redeclare as settable
- (void) priv_updateLocalAddress;
@end


@implementation MYPortMapper


- (id) initWithLocalPort: (UInt16)localPort
{
    self = [super init];
    if (self != nil) {
        _localPort = localPort;
        _mapTCP = YES;
        self.continuous = YES;
        [self priv_updateLocalAddress];
    }
    return self;
}

- (id) initWithNullMapping
{
    // A PortMapper with no port or protocols will cause the DNSService to look up 
    // our public address without creating a mapping.
    if ([self initWithLocalPort: 0]) {
        _mapTCP = _mapUDP = NO;
    }
    return self;
}


- (void) dealloc
{
    [_publicAddress release];
    [_localAddress release];
    [super dealloc];
}


@synthesize localAddress=_localAddress, publicAddress=_publicAddress,
            mapTCP=_mapTCP, mapUDP=_mapUDP,
            desiredPublicPort=_desiredPublicPort;


- (BOOL) isMapped
{
    return ! $equal(_publicAddress,_localAddress);
}

- (void) priv_updateLocalAddress 
{
    IPAddress *localAddress = [IPAddress localAddressWithPort: _localPort];
    if (!$equal(localAddress,_localAddress))
        self.localAddress = localAddress;
}


static IPAddress* makeIPAddr( UInt32 rawAddr, UInt16 port ) {
    if (rawAddr)
        return [[[IPAddress alloc] initWithIPv4: rawAddr port: port] autorelease];
    else
        return nil;
}

/** Called whenever the port mapping changes (see comment for callback, below.) */
- (void) priv_portMapStatus: (DNSServiceErrorType)errorCode 
              publicAddress: (UInt32)rawPublicAddress
                 publicPort: (UInt16)publicPort
{
    if( errorCode==kDNSServiceErr_NoError ) {
        if( rawPublicAddress==0 || (publicPort==0 && (_mapTCP || _mapUDP)) ) {
            LogTo(PortMapper,@"%@: No port-map available", self);
            errorCode = kDNSServiceErr_NATPortMappingUnsupported;
        }
    }

    [self priv_updateLocalAddress];
    IPAddress *publicAddress = makeIPAddr(rawPublicAddress,publicPort);
    if (!$equal(publicAddress,_publicAddress))
        self.publicAddress = publicAddress;
    
    if( ! errorCode ) {
        LogTo(PortMapper,@"%@: Public addr is %@ (mapped=%i)",
              self, self.publicAddress, self.isMapped);
    }

    [self gotResponse: errorCode];
    [[NSNotificationCenter defaultCenter] postNotificationName: MYPortMapperChangedNotification
                                                        object: self];
}


/** Asynchronous callback from DNSServiceNATPortMappingCreate.
    This is invoked whenever the status of the port mapping changes.
    All it does is dispatch to the object's priv_portMapStatus:publicAddress:publicPort: method. */
static void portMapCallback (
                      DNSServiceRef                    sdRef,
                      DNSServiceFlags                  flags,
                      uint32_t                         interfaceIndex,
                      DNSServiceErrorType              errorCode,
                      uint32_t                         publicAddress,    /* four byte IPv4 address in network byte order */
                      DNSServiceProtocol               protocol,
                      uint16_t                         privatePort,
                      uint16_t                         publicPort,       /* may be different than the requested port */
                      uint32_t                         ttl,              /* may be different than the requested ttl */
                      void                             *context
                      )
{
    @try{
        [(MYPortMapper*)context priv_portMapStatus: errorCode 
                                     publicAddress: publicAddress
                                        publicPort: ntohs(publicPort)];  // port #s in network byte order!
    }catchAndReport(@"PortMapper");
}


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    DNSServiceProtocol protocols = 0;
    if( _mapTCP ) protocols |= kDNSServiceProtocol_TCP;
    if( _mapUDP ) protocols |= kDNSServiceProtocol_UDP;
    return DNSServiceNATPortMappingCreate(sdRefPtr, 
                                          kDNSServiceFlagsShareConnection, 
                                          0 /*interfaceIndex*/, 
                                          protocols,
                                          htons(_localPort),
                                          htons(_desiredPublicPort),
                                          0 /*ttl*/,
                                          &portMapCallback, 
                                          self);
}


- (BOOL) waitTillOpened
{
    if( ! self.serviceRef )
        if( ! [self start] )
            return NO;
    [self waitForReply];
    return (self.error==0);
}


+ (IPAddress*) findPublicAddress
{
    IPAddress *addr = nil;
    MYPortMapper *mapper = [[self alloc] initWithNullMapping];
    mapper.continuous = NO;
    if( [mapper waitTillOpened] )
        addr = [mapper.publicAddress retain];
    [mapper stop];
    [mapper release];
    return [addr autorelease];
}


@end


/*
 Copyright (c) 2008-2009, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
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
