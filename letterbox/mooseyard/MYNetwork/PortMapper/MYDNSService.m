//
//  MYDNSService.m
//  MYNetwork
//
//  Created by Jens Alfke on 4/23/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYDNSService.h"
#import "CollectionUtils.h"
#import "Logging.h"
#import "Test.h"
#import "ExceptionUtils.h"

#import <dns_sd.h>


static void serviceCallback(CFSocketRef s, 
                            CFSocketCallBackType type,
                            CFDataRef address,
                            const void *data,
                            void *clientCallBackInfo);
        

@implementation MYDNSService


- (void) dealloc
{
    Log(@"DEALLOC %@ %p", self.class,self);
    if( _serviceRef )
        [self cancel];
    [super dealloc];
}

- (void) finalize
{
    if( _serviceRef )
        [self cancel];
    [super finalize];
}


- (DNSServiceErrorType) error {
    return _error;
}

- (void) setError: (DNSServiceErrorType)error {
    if (error)
        Warn(@"%@ error := %i", self,error);
    _error = error;
}


@synthesize continuous=_continuous, serviceRef=_serviceRef, usePrivateConnection=_usePrivateConnection;


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    AssertAbstractMethod();
}


- (void) gotResponse: (DNSServiceErrorType)errorCode {
    _gotResponse = YES;
    if (!_continuous)
        [self cancel];
    if (errorCode && errorCode != _error) {
        Log(@"%@ got error %i", self,errorCode);
        self.error = errorCode;
    }
}


- (BOOL) start
{
    if (_serviceRef)
        return YES;     // already started

    if (_error)
        self.error = 0;
    _gotResponse = NO;

    if (!_usePrivateConnection) {
        _connection = [[MYDNSConnection sharedConnection] retain];
        if (!_connection) {
            self.error = kDNSServiceErr_Unknown;
            return NO;
        }
        _serviceRef = _connection.connectionRef;
    }
    
    // Ask the subclass to create a DNSServiceRef:
    _error = [self createServiceRef: &_serviceRef];
    if (_error) {
        _serviceRef = NULL;
        setObj(&_connection,nil);
        if (!_error)
            self.error = kDNSServiceErr_Unknown;
        LogTo(DNS,@"Failed to open %@ -- err=%i",self,_error);
        return NO;
    }
    
    if (!_connection)
        _connection = [[MYDNSConnection alloc] initWithServiceRef: _serviceRef];
    
    LogTo(DNS,@"Started %@",self);
    return YES; // Succeeded
}


- (BOOL) waitForReply {
    if( ! _serviceRef )
        if( ! [self start] )
            return NO;
    // Run the runloop until there's either an error or a result:
    _gotResponse = NO;
    LogTo(DNS,@"Waiting for reply to %@...", self);
    while( !_gotResponse )
        if( ! [_connection processResult] )
            break;
    LogTo(DNS,@"    ...got reply");
    return (self.error==0);
}


- (void) cancel
{
    if( _serviceRef ) {
        LogTo(DNS,@"Stopped %@",self);
        DNSServiceRefDeallocate(_serviceRef);
        _serviceRef = NULL;
        
        setObj(&_connection,nil);
    }
}


- (void) stop
{
    [self cancel];
    if (_error)
        self.error = 0;
}


- (BOOL) isRunning {
    return _serviceRef != NULL;
}


+ (NSString*) fullNameOfService: (NSString*)serviceName
                         ofType: (NSString*)type
                       inDomain: (NSString*)domain
{
    //FIX: Do I need to un-escape the serviceName?
    Assert(type);
    Assert(domain);
    char fullName[kDNSServiceMaxDomainName];
    if (DNSServiceConstructFullName(fullName, serviceName.UTF8String, type.UTF8String, domain.UTF8String) == 0)
        return [NSString stringWithUTF8String: fullName];
    else
        return nil;
}


@end


#pragma mark -
#pragma mark SHARED CONNECTION:


@interface MYDNSConnection ()
- (BOOL) open;
@end


@implementation MYDNSConnection


MYDNSConnection *sSharedConnection;


- (id) init
{
    DNSServiceRef connectionRef = NULL;
    DNSServiceErrorType err = DNSServiceCreateConnection(&connectionRef);
    if (err || !connectionRef) {
        Warn(@"MYDNSConnection: DNSServiceCreateConnection failed, err=%i", err);
        [self release];
        return nil;
    }
    return [self initWithServiceRef: connectionRef];
}


- (id) initWithServiceRef: (DNSServiceRef)serviceRef
{
    Assert(serviceRef);
    self = [super init];
    if (self != nil) {
        _connectionRef = serviceRef;
        LogTo(DNS,@"INIT %@", self);
        if (![self open]) {
            [self release];
            return nil;
        }
    }
    return self;
}


+ (MYDNSConnection*) sharedConnection {
    @synchronized(self) {
        if (!sSharedConnection)
            sSharedConnection = [[[self alloc] init] autorelease];
    }
    return sSharedConnection;
}


- (void) dealloc
{
    LogTo(DNS,@"DEALLOC %@", self);
    [self close];
    [super dealloc];
}

- (void) finalize {
    [self close];
    [super finalize];
}


@synthesize connectionRef=_connectionRef;

- (NSString*) description {
    return $sprintf(@"%@[conn=%p]", self.class,_connectionRef);
}

- (BOOL) open {
    if (_runLoopSource)
        return YES;        // Already opened
    
    // Wrap a CFSocket around the service's socket:
    CFSocketContext ctxt = { 0, self, CFRetain, CFRelease, NULL };
    _socket = CFSocketCreateWithNative(NULL, 
                                                       DNSServiceRefSockFD(_connectionRef), 
                                                       kCFSocketReadCallBack, 
                                                       &serviceCallback, &ctxt);
    if( _socket ) {
        CFSocketSetSocketFlags(_socket, 
                               CFSocketGetSocketFlags(_socket) & ~kCFSocketCloseOnInvalidate);
        // Attach the socket to the runloop so the serviceCallback will be invoked:
        _runLoopSource = CFSocketCreateRunLoopSource(NULL, _socket, 0);
        if( _runLoopSource ) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopCommonModes);
            // Success!
            LogTo(DNS,@"Successfully opened %@", self);
            return YES;
        }
    }
    
    // Failure:
    Warn(@"Failed to connect %@ to runloop", self);
    [self close];
    return NO;
}


- (void) close {
    @synchronized(self) {
        if( _runLoopSource ) {
            CFRunLoopSourceInvalidate(_runLoopSource);
            CFRelease(_runLoopSource);
            _runLoopSource = NULL;
        }
        if( _socket ) {
            CFSocketInvalidate(_socket);
            CFRelease(_socket);
            _socket = NULL;
        }
        if( _connectionRef ) {
            LogTo(DNS,@"Closed %@",self);
            DNSServiceRefDeallocate(_connectionRef);
            _connectionRef = NULL;
        }
        
        if (self==sSharedConnection)
            sSharedConnection = nil;
    }
}


- (BOOL) processResult {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    LogTo(DNS,@"---serviceCallback----");
    DNSServiceErrorType err = DNSServiceProcessResult(_connectionRef);
    if (err) {
        Warn(@"%@: DNSServiceProcessResult failed, err=%i !!!", self,err);
        //FIX: Are errors here fatal, meaning I should close the connection?
        // I've run into infinite loops constantly getting kDNSServiceErr_ServiceNotRunning
        // or kDNSServiceErr_BadReference ...
    }
    [pool drain];
    return !err;
}


/** CFSocket callback, informing us that _socket has data available, which means
    that the DNS service has an incoming result to be processed. This will end up invoking
    the service's specific callback. */
static void serviceCallback(CFSocketRef s, 
                            CFSocketCallBackType type,
                            CFDataRef address, const void *data, void *clientCallBackInfo)
{
    MYDNSConnection *connection = clientCallBackInfo;
    [connection processResult];
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
