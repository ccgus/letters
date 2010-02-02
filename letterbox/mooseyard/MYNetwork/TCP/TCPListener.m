//
//  TCPListener.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Portions based on TCPServer class from Apple's "CocoaEcho" sample code.

#import "TCPListener.h"
#import "TCPConnection.h"

#import "Logging.h"
#import "Test.h"
#import "ExceptionUtils.h"
#import "IPAddress.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>


static void TCPListenerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, 
                                      CFDataRef address, const void *data, void *info);

@interface TCPListener()
- (void) _openBonjour;
- (void) _closeBonjour;
@property BOOL bonjourPublished;
@property NSInteger bonjourError;
- (void) _updateTXTRecord;
@end


@implementation TCPListener


- (id) init
{
    self = [super init];
    if (self != nil) {
        _connectionClass = [TCPConnection class];
    }
    return self;
}


- (id) initWithPort: (UInt16)port
{
    self = [self init];
    if (self != nil) {
        _port = port;
    }
    return self;
}


- (void) dealloc 
{
    [self close];
    LogTo(TCP,@"DEALLOC %@",self);
    [super dealloc];
}


@synthesize port=_port, useIPv6=_useIPv6,
            bonjourServiceType=_bonjourServiceType, bonjourServiceOptions=_bonjourServiceOptions,
            bonjourPublished=_bonjourPublished, bonjourError=_bonjourError,
            bonjourService=_netService,
            pickAvailablePort=_pickAvailablePort;


- (id<TCPListenerDelegate>) delegate                      {return _delegate;}
- (void) setDelegate: (id<TCPListenerDelegate>) delegate  {_delegate = delegate;}


- (NSString*) description
{
    return $sprintf(@"%@[port %hu]",self.class,_port);
}


// Stores the last error from CFSocketCreate or CFSocketSetAddress into *outError.
static void* getLastCFSocketError( NSError **outError ) {
    if( outError )
        *outError = [NSError errorWithDomain: NSPOSIXErrorDomain code: errno userInfo: nil];
    return NULL;
}

// Closes a socket (if it's not already NULL), and returns NULL to assign to it.
static CFSocketRef closeSocket( CFSocketRef socket ) {
    if( socket ) {
        CFSocketInvalidate(socket);
        CFRelease(socket);
    }
    return NULL;
}

// opens a socket of a given protocol, either ipv4 or ipv6.
- (CFSocketRef) _openProtocol: (SInt32) protocolFamily 
                      address: (struct sockaddr*)address
                        error: (NSError**)error
{
    CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
    CFSocketRef socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP,
                                        kCFSocketAcceptCallBack, &TCPListenerAcceptCallBack, &socketCtxt);
    if( ! socket ) 
        return getLastCFSocketError(error);   // CFSocketCreate leaves error code in errno
    
    int yes = 1;
    setsockopt(CFSocketGetNative(socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
    
    NSData *addressData = [NSData dataWithBytes:address length:address->sa_len];
    if (kCFSocketSuccess != CFSocketSetAddress(socket, (CFDataRef)addressData)) {
        getLastCFSocketError(error);
        return closeSocket(socket);
    }
    // set up the run loop source for the socket
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
    CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
    CFRelease(source);
    return socket;
}

- (BOOL) _failedToOpen: (NSError*)error
{
    LogTo(TCP,@"%@ failed to open: %@",self,error);
    [self tellDelegate: @selector(listener:failedToOpen:) withObject: error];
    return NO;
}


- (BOOL) open: (NSError**)outError 
{
    // set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
    do{
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(_port);
        addr4.sin_addr.s_addr = htonl(INADDR_ANY);

        NSError *error;
        _ipv4socket = [self _openProtocol: PF_INET address: (struct sockaddr*)&addr4 error: &error];
        if( ! _ipv4socket ) {
            if( error.code==EADDRINUSE && _pickAvailablePort && _port<0xFFFF ) {
                LogTo(BLIPVerbose,@"%@: port busy, trying %hu...",self,_port+1);
                self.port += 1;        // try the next port
            } else {
                if( outError ) *outError = error;
                return [self _failedToOpen: error];
            }
        }
    }while( ! _ipv4socket );
    
    if (0 == _port) {
        // now that the binding was successful, we get the port number 
        NSData *addr = [NSMakeCollectable( CFSocketCopyAddress(_ipv4socket) ) autorelease];
        const struct sockaddr_in *addr4 = addr.bytes;
        self.port = ntohs(addr4->sin_port);
    }
    
    if( _useIPv6 ) {
        // set up the IPv6 endpoint
        struct sockaddr_in6 addr6;
        memset(&addr6, 0, sizeof(addr6));
        addr6.sin6_len = sizeof(addr6);
        addr6.sin6_family = AF_INET6;
        addr6.sin6_port = htons(_port);
        memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
        
        NSError *error;
        _ipv6socket = [self _openProtocol: PF_INET6 address: (struct sockaddr*)&addr6 error: &error];
        if( ! _ipv6socket ) {
            _ipv4socket = closeSocket(_ipv4socket);
            [self _failedToOpen: error];
            if (outError) *outError = error;
            return NO;
        }
    }
    
    [self _openBonjour];

    LogTo(TCP,@"%@ is open",self);
    [self tellDelegate: @selector(listenerDidOpen:) withObject: nil];
    return YES;
}

- (BOOL) open
{
    return [self open: nil];
}
    

- (void) close 
{
    if( _ipv4socket ) {
        [self _closeBonjour];
        _ipv4socket = closeSocket(_ipv4socket);
        _ipv6socket = closeSocket(_ipv6socket);

        LogTo(BLIP,@"%@ is closed",self);
        [self tellDelegate: @selector(listenerDidClose:) withObject: nil];
    }
}


- (BOOL) isOpen
{
    return _ipv4socket != NULL;
}


#pragma mark -
#pragma mark ACCEPTING CONNECTIONS:


@synthesize connectionClass = _connectionClass;


- (BOOL) acceptConnection: (CFSocketNativeHandle)socket
{
    IPAddress *addr = [IPAddress addressOfSocket: socket];
    if( ! addr )
        return NO;
    if( [_delegate respondsToSelector: @selector(listener:shouldAcceptConnectionFrom:)]
       && ! [_delegate listener: self shouldAcceptConnectionFrom: addr] )
        return NO;
    
    Assert(_connectionClass);
    TCPConnection *conn = [[self.connectionClass alloc] initIncomingFromSocket: socket
                                                                      listener: self];
    if( ! conn )
        return NO;
    
    if( _sslProperties ) {
        conn.SSLProperties = _sslProperties;
        [conn setSSLProperty: $true forKey: (id)kCFStreamSSLIsServer];
    }
    [conn open];
    [self tellDelegate: @selector(listener:didAcceptConnection:) withObject: conn];
    return YES;
}


static void TCPListenerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) 
{
    TCPListener *server = (TCPListener *)info;
    if (kCFSocketAcceptCallBack == type) { 
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        BOOL accepted = NO;
        @try{
            accepted = [server acceptConnection: nativeSocketHandle];
        }catchAndReport(@"TCPListenerAcceptCallBack");
        if( ! accepted )
            close(nativeSocketHandle);
    }
}


#pragma mark -
#pragma mark BONJOUR:


- (void) _openBonjour
{
    if( self.isOpen && _bonjourServiceType && !_netService) {
        // instantiate the NSNetService object that will advertise on our behalf.
        _netService = [[NSNetService alloc] initWithDomain: @"local." 
                                                      type: _bonjourServiceType
                                                      name: _bonjourServiceName ?:@""
                                                      port: _port];
        if( _netService ) {
            [_netService setDelegate:self];
            if( _bonjourTXTRecord )
                [self _updateTXTRecord];
            [_netService publishWithOptions: _bonjourServiceOptions];
        } else {
            self.bonjourError = -1;
            Warn(@"%@: Failed to create NSNetService",self);
        }
    }
}

- (void) _closeBonjour
{
    if( _netService ) {
        [_netService stop];
        [_netService release];
        _netService = nil;
        self.bonjourPublished = NO;
    }
    if( self.bonjourError )
        self.bonjourError = 0;
}


- (NSString*) bonjourServiceName {return _bonjourServiceName;}

- (void) setBonjourServiceName: (NSString*)name
{
    if( ! $equal(name,_bonjourServiceName) ) {
        [self _closeBonjour];
        setObj(&_bonjourServiceName,name);
        [self _openBonjour];
    }
}


- (NSDictionary*) bonjourTXTRecord
{
    return _bonjourTXTRecord;
}

- (void) setBonjourTXTRecord: (NSDictionary*)txt
{
    if( ifSetObj(&_bonjourTXTRecord,txt) )
        [self _updateTXTRecord];
}

- (void) _updateTXTRecord
{
    if( _netService ) {
        NSData *data;
        if( _bonjourTXTRecord ) {
            data = [NSNetService dataFromTXTRecordDictionary: _bonjourTXTRecord];
            if( data )
                LogTo(BLIP,@"%@: Set %u-byte TXT record", self,data.length);
            else
                Warn(@"TCPListener: Couldn't convert txt dict to data: %@",_bonjourTXTRecord);
        } else
            data = nil;
        [_netService setTXTRecordData: data];
    }
}


- (void)netServiceWillPublish:(NSNetService *)sender
{
    LogTo(BLIP,@"%@: Advertising %@",self,sender);
    self.bonjourPublished = YES;
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    self.bonjourError = [[errorDict objectForKey:NSNetServicesErrorCode] intValue];
    LogTo(BLIP,@"%@: Failed to advertise %@: error %i",self,sender,self.bonjourError);
    [_netService release];
    _netService = nil;
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    LogTo(BLIP,@"%@: Stopped advertising %@",self,sender);
    self.bonjourPublished = NO;
    [_netService release];
    _netService = nil;
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
