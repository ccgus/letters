//
//  BLIPTest.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/13/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#ifndef NDEBUG


#import "BLIPRequest.h"
#import "BLIPProperties.h"
#import "BLIPConnection.h"

#import "IPAddress.h"
#import "Target.h"
#import "CollectionUtils.h"
#import "Logging.h"
#import "Test.h"

#import <Security/Security.h>
#import <SecurityInterface/SFChooseIdentityPanel.h>

@interface TCPEndpoint ()
+ (NSString*) describeCert: (SecCertificateRef)cert;
+ (NSString*) describeIdentity: (SecIdentityRef)identity;
@end


#define kListenerHost               @"localhost"
#define kListenerPort               46353
#define kSendInterval               0.5
#define kNBatchedMessages           20
#define kUseCompression             YES
#define kUrgentEvery                4
#define kListenerCloseAfter         50
#define kClientAcceptCloseRequest   YES

#define kListenerUsesSSL            YES     // Does the listener (server) use an SSL connection?
#define kListenerRequiresClientCert YES     // Does the listener require clients to have an SSL cert?
#define kClientRequiresSSL          YES     // Does the client require the listener to use SSL?
#define kClientUsesSSLCert          YES     // Does the client use an SSL cert?


static SecIdentityRef ChooseIdentity( NSString *prompt ) {
    NSMutableArray *identities = [NSMutableArray array];
    SecKeychainRef kc;
    SecKeychainCopyDefault(&kc);
    SecIdentitySearchRef search;
    SecIdentitySearchCreate(kc, CSSM_KEYUSE_ANY, &search);
    SecIdentityRef identity;
    while (SecIdentitySearchCopyNext(search, &identity) == noErr) {
        [identities addObject: (id)identity];
		CFRelease( identity );
	}
    CFRelease(search);
    Log(@"Found %u identities -- prompting '%@'", identities.count, prompt);
    if (identities.count > 0) {
        SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
        if ([panel runModalForIdentities: identities message: prompt] == NSOKButton) {
            Log(@"Using SSL identity: %@", panel.identity);
            return panel.identity;
        }
    }
    return NULL;
}

static SecIdentityRef GetClientIdentity(void) {
    return ChooseIdentity(@"Choose an identity for the BLIP Client Test:");
}

static SecIdentityRef GetListenerIdentity(void) {
    return ChooseIdentity(@"Choose an identity for the BLIP Listener Test:");
}


#pragma mark -
#pragma mark CLIENT TEST:


@interface BLIPConnectionTester : NSObject <BLIPConnectionDelegate>
{
    BLIPConnection *_conn;
    NSMutableDictionary *_pending;
}

@end


@implementation BLIPConnectionTester

- (id) init
{
    self = [super init];
    if (self != nil) {
        Log(@"** INIT %@",self);
        _pending = [[NSMutableDictionary alloc] init];
        IPAddress *addr = [[[IPAddress alloc] initWithHostname: kListenerHost port: kListenerPort] autorelease];
        _conn = [[BLIPConnection alloc] initToAddress: addr];
        if( ! _conn ) {
            [self release];
            return nil;
        }
        if( kClientUsesSSLCert ) {
            [_conn setPeerToPeerIdentity: GetClientIdentity()];
        } else if( kClientRequiresSSL ) {
            _conn.SSLProperties = $mdict({kTCPPropertySSLAllowsAnyRoot, $true},
                                        {(id)kCFStreamSSLPeerName, [NSNull null]});
        }
        _conn.delegate = self;
        Log(@"** Opening connection...");
        [_conn open];
    }
    return self;
}

- (void) dealloc
{
    Log(@"** %@ closing",self);
    [_conn close];
    [_conn release];
    [super dealloc];
}

- (void) sendAMessage
{
    if( _conn.status==kTCP_Open || _conn.status==kTCP_Opening ) {
        if(_pending.count<100) {
            Log(@"** Sending a message that will fail to be handled...");
            BLIPRequest *q = [_conn requestWithBody: nil
                                         properties: $dict({@"Profile", @"BLIPTest/DontHandleMe"},
                                                           {@"User-Agent", @"BLIPConnectionTester"},
                                                           {@"Date", [[NSDate date] description]})];
            BLIPResponse *response = [q send];
            Assert(response);
            Assert(q.number>0);
            Assert(response.number==q.number);
            [_pending setObject: [NSNull null] forKey: $object(q.number)];
            response.onComplete = $target(self,responseArrived:);
            
            Log(@"** Sending another %i messages...", kNBatchedMessages);
            for( int i=0; i<kNBatchedMessages; i++ ) {
                size_t size = random() % 32768;
                NSMutableData *body = [NSMutableData dataWithLength: size];
                UInt8 *bytes = body.mutableBytes;
                for( size_t i=0; i<size; i++ )
                    bytes[i] = i % 256;
                
                q = [_conn requestWithBody: body
                                 properties: $dict({@"Profile", @"BLIPTest/EchoData"},
                                                   {@"Content-Type", @"application/octet-stream"},
                                                   {@"User-Agent", @"BLIPConnectionTester"},
                                                   {@"Date", [[NSDate date] description]},
                                                   {@"Size",$sprintf(@"%u",size)})];
                Assert(q);
                if( kUseCompression && (random()%2==1) )
                    q.compressed = YES;
                if( random()%16 > 12 )
                    q.urgent = YES;
                BLIPResponse *response = [q send];
                Assert(response);
                Assert(q.number>0);
                Assert(response.number==q.number);
                [_pending setObject: $object(size) forKey: $object(q.number)];
                response.onComplete = $target(self,responseArrived:);
            }
        } else {
            Warn(@"There are %u pending messages; waiting for the listener to catch up...",_pending.count);
        }
        [self performSelector: @selector(sendAMessage) withObject: nil afterDelay: kSendInterval];
    }
}

- (void) responseArrived: (BLIPResponse*)response
{
    Log(@"********** called responseArrived: %@",response);
}

- (void) connectionDidOpen: (TCPConnection*)connection
{
    Log(@"** %@ didOpen",connection);
    [self sendAMessage];
}
- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert
{
    Log(@"** %@ authorizeSSLPeer: %@",self, [TCPEndpoint describeCert:peerCert]);
    return peerCert != nil;
}
- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    Warn(@"** %@ failedToOpen: %@",connection,error);
    CFRunLoopStop(CFRunLoopGetCurrent());
}
- (void) connectionDidClose: (TCPConnection*)connection
{
    if (connection.error)
        Warn(@"** %@ didClose: %@", connection,connection.error);
    else
        Log(@"** %@ didClose", connection);
    setObj(&_conn,nil);
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    CFRunLoopStop(CFRunLoopGetCurrent());
}
- (BOOL) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    Log(@"***** %@ received %@",connection,request);
    [request respondWithData: request.body contentType: request.contentType];
    return YES;
}

- (void) connection: (BLIPConnection*)connection receivedResponse: (BLIPResponse*)response
{
    Log(@"********** %@ received %@",connection,response);
    id sizeObj = [_pending objectForKey: $object(response.number)];
    Assert(sizeObj);
    
    if (sizeObj == [NSNull null]) {
        AssertEqual(response.error.domain, BLIPErrorDomain);
        AssertEq(response.error.code, kBLIPError_NotFound);
    } else {
        if( response.error )
            Warn(@"Got error response: %@",response.error);
        else {
            NSData *body = response.body;
            size_t size = body.length;
            Assert(size<32768);
            const UInt8 *bytes = body.bytes;
            for( size_t i=0; i<size; i++ )
                AssertEq(bytes[i],i % 256);
            AssertEq(size,[sizeObj unsignedIntValue]);
        }
    }
    [_pending removeObjectForKey: $object(response.number)];
    Log(@"Now %u replies pending", _pending.count);
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection
{
    BOOL response = kClientAcceptCloseRequest;
    Log(@"***** %@ received a close request; returning %i",connection,response);
    return response;
}


@end


TestCase(BLIPConnection) {
    SecKeychainSetUserInteractionAllowed(true);
    BLIPConnectionTester *tester = [[BLIPConnectionTester alloc] init];
    CAssert(tester);
    
    [[NSRunLoop currentRunLoop] run];
    
    Log(@"** Runloop stopped");
    [tester release];
}




#pragma mark LISTENER TEST:


@interface BLIPTestListener : NSObject <TCPListenerDelegate, BLIPConnectionDelegate>
{
    BLIPListener *_listener;
    int _nReceived;
}

@end


@implementation BLIPTestListener

- (id) init
{
    self = [super init];
    if (self != nil) {
        _listener = [[BLIPListener alloc] initWithPort: kListenerPort];
        _listener.delegate = self;
        _listener.pickAvailablePort = YES;
        _listener.bonjourServiceType = @"_bliptest._tcp";
        if( kListenerUsesSSL ) {
            [_listener setPeerToPeerIdentity: GetListenerIdentity()];
            if (!kListenerRequiresClientCert)
                [_listener setSSLProperty: $object(kTCPTryAuthenticate) 
                                   forKey: kTCPPropertySSLClientSideAuthentication];
        }
        Assert( [_listener open] );
        Log(@"%@ is listening...",self);
    }
    return self;
}

- (void) dealloc
{
    Log(@"%@ closing",self);
    [_listener close];
    [_listener release];
    [super dealloc];
}

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection
{
    Log(@"** %@ accepted %@",self,connection);
    connection.delegate = self;
}

- (void) listener: (TCPListener*)listener failedToOpen: (NSError*)error
{
    Log(@"** BLIPTestListener failed to open: %@",error);
}

- (void) listenerDidOpen: (TCPListener*)listener   {Log(@"** BLIPTestListener did open");}
- (void) listenerDidClose: (TCPListener*)listener   {Log(@"** BLIPTestListener did close");}

- (BOOL) listener: (TCPListener*)listener shouldAcceptConnectionFrom: (IPAddress*)address
{
    Log(@"** %@ shouldAcceptConnectionFrom: %@",self,address);
    return YES;
}


- (void) connectionDidOpen: (TCPConnection*)connection
{
    Log(@"** %@ didOpen [SSL=%@]",connection,connection.actualSecurityLevel);
    _nReceived = 0;
}
- (BOOL) connection: (TCPConnection*)connection authorizeSSLPeer: (SecCertificateRef)peerCert
{
    Log(@"** %@ authorizeSSLPeer: %@",self, [TCPEndpoint describeCert:peerCert]);
    return peerCert != nil || ! kListenerRequiresClientCert;
}
- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    Log(@"** %@ failedToOpen: %@",connection,error);
}
- (void) connectionDidClose: (TCPConnection*)connection
{
    if (connection.error)
        Warn(@"** %@ didClose: %@", connection,connection.error);
    else
        Log(@"** %@ didClose", connection);
    [connection release];
}
- (BOOL) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    Log(@"***** %@ received %@",connection,request);
    
    if ([request.profile isEqualToString: @"BLIPTest/EchoData"]) {
        NSData *body = request.body;
        size_t size = body.length;
        Assert(size<32768);
        const UInt8 *bytes = body.bytes;
        for( size_t i=0; i<size; i++ )
            AssertEq(bytes[i],i % 256);
        
        AssertEqual([request valueOfProperty: @"Content-Type"], @"application/octet-stream");
        Assert([request valueOfProperty: @"User-Agent"] != nil);
        AssertEq((size_t)[[request valueOfProperty: @"Size"] intValue], size);

        [request respondWithData: body contentType: request.contentType];
    } else if ([request.profile isEqualToString: @"BLIPTest/DontHandleMe"]) {
        // Deliberately don't handle this, to test unhandled request handling.
        return NO;
    } else {
        Assert(NO, @"Unknown profile in request %@", request);
    }
    
    if( ++ _nReceived == kListenerCloseAfter ) {
        Log(@"********** Closing BLIPTestListener after %i requests",_nReceived);
        [connection close];
    }
    return YES;
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection;
{
    Log(@"***** %@ received a close request",connection);
    return YES;
}

- (void) connection: (BLIPConnection*)connection closeRequestFailedWithError: (NSError*)error
{
    Log(@"***** %@'s close request failed: %@",connection,error);
}


@end


TestCase(BLIPListener) {
    EnableLogTo(BLIP,YES);
    EnableLogTo(PortMapper,YES);
    EnableLogTo(Bonjour,YES);
    SecKeychainSetUserInteractionAllowed(true);
    BLIPTestListener *listener = [[BLIPTestListener alloc] init];
    
    [[NSRunLoop currentRunLoop] run];
    
    [listener release];
}


#endif


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
