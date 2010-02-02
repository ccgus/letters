//
//  BLIPConnection.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPConnection.h"
#import "BLIP_Internal.h"
#import "TCP_Internal.h"
#import "BLIPReader.h"
#import "BLIPWriter.h"
#import "BLIPDispatcher.h"

#import "Logging.h"
#import "Test.h"
#import "ExceptionUtils.h"
#import "Target.h"


NSString* const BLIPErrorDomain = @"BLIP";

NSError *BLIPMakeError( int errorCode, NSString *message, ... )
{
    va_list args;
    va_start(args,message);
    message = [[NSString alloc] initWithFormat: message arguments: args];
    va_end(args);
    LogTo(BLIP,@"BLIPError #%i: %@",errorCode,message);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject: message
                                                         forKey: NSLocalizedDescriptionKey];
    [message release];
    return [NSError errorWithDomain: BLIPErrorDomain code: errorCode userInfo: userInfo];
}


@interface BLIPConnection ()
- (void) _handleCloseRequest: (BLIPRequest*)request;
@end


@implementation BLIPConnection


- (void) dealloc
{
    [_dispatcher release];
    [super dealloc];
}

- (Class) readerClass                                       {return [BLIPReader class];}
- (Class) writerClass                                       {return [BLIPWriter class];}
- (id<BLIPConnectionDelegate>) delegate                     {return (id)_delegate;}
- (void) setDelegate: (id<BLIPConnectionDelegate>)delegate  {_delegate = delegate;}


#pragma mark -
#pragma mark RECEIVING:


- (BLIPDispatcher*) dispatcher
{
    if( ! _dispatcher ) {
        _dispatcher = [[BLIPDispatcher alloc] init];
        _dispatcher.parent = ((BLIPListener*)self.server).dispatcher;
    }
    return _dispatcher;
}


- (BOOL) _dispatchMetaRequest: (BLIPRequest*)request
{
    NSString* profile = request.profile;
    if( [profile isEqualToString: kBLIPProfile_Bye] ) {
        [self _handleCloseRequest: request];
        return YES;
    }
    return NO;
}


- (void) _dispatchRequest: (BLIPRequest*)request
{
    LogTo(BLIP,@"Received all of %@",request.descriptionWithProperties);
    @try{
        BOOL handled;
        if( request._flags & kBLIP_Meta )
            handled =[self _dispatchMetaRequest: request];
        else {
            handled = [self.dispatcher dispatchMessage: request];
            if (!handled && [_delegate respondsToSelector: @selector(connection:receivedRequest:)])
                handled = [_delegate connection: self receivedRequest: request];
        }
        
        if (!handled) {
            LogTo(BLIP,@"No handler found for incoming %@",request);
            [request respondWithErrorCode: kBLIPError_NotFound message: @"No handler was found"];
        } else if( ! request.noReply && ! request.repliedTo ) {
            LogTo(BLIP,@"Returning default empty response to %@",request);
            [request respondWithData: nil contentType: nil];
        }
    }@catch( NSException *x ) {
        MYReportException(x,@"Dispatching BLIP request");
        [request respondWithException: x];
    }
}

- (void) _dispatchResponse: (BLIPResponse*)response
{
    LogTo(BLIP,@"Received all of %@",response);
    [self tellDelegate: @selector(connection:receivedResponse:) withObject: response];
}


#pragma mark -
#pragma mark SENDING:


- (BLIPRequest*) request
{
    return [[[BLIPRequest alloc] _initWithConnection: self body: nil properties: nil] autorelease];
}

- (BLIPRequest*) requestWithBody: (NSData*)body
                      properties: (NSDictionary*)properties
{
    return [[[BLIPRequest alloc] _initWithConnection: self body: body properties: properties] autorelease];
}

- (BLIPResponse*) sendRequest: (BLIPRequest*)request
{
    if (!request.isMine || request.sent) {
        // This was an incoming request that I'm being asked to forward or echo;
        // or it's an outgoing request being sent to multiple connections.
        // Since a particular BLIPRequest can only be sent once, make a copy of it to send:
        request = [[request mutableCopy] autorelease];
    }
    BLIPConnection *itsConnection = request.connection;
    if( itsConnection==nil )
        request.connection = self;
    else
        Assert(itsConnection==self,@"%@ is already assigned to a different BLIPConnection",request);
    return [request send];
}


#pragma mark -
#pragma mark CLOSING:


- (void) _beginClose
{
    // Override of TCPConnection method. Instead of closing the socket, send a 'bye' request:
    if( ! _blipClosing ) {
        LogTo(BLIPVerbose,@"Sending close request...");
        BLIPRequest *r = [self request];
        [r _setFlag: kBLIP_Meta value: YES];
        r.profile = kBLIPProfile_Bye;
        BLIPResponse *response = [r send];
        response.onComplete = $target(self,_receivedCloseResponse:);
    }
    // Put the writer in close mode, to prevent client from sending any more requests:
    [self.writer close];
}

- (void) _receivedCloseResponse: (BLIPResponse*)response
{
    NSError *error = response.error;
    LogTo(BLIPVerbose,@"Received close response: error=%@",error);
    if( error ) {
        [self _unclose];
        [self tellDelegate: @selector(connection:closeRequestFailedWithError:) withObject: error];
    } else {
        // Now finally close the socket:
        [super _beginClose];
    }
}


- (void) _handleCloseRequest: (BLIPRequest*)request
{
    LogTo(BLIPVerbose,@"Received a close request");
    if( [_delegate respondsToSelector: @selector(connectionReceivedCloseRequest:)] )
        if( ! [_delegate connectionReceivedCloseRequest: self] ) {
            LogTo(BLIPVerbose,@"Responding with denial of close request");
            [request respondWithErrorCode: kBLIPError_Forbidden message: @"Close request denied"];
            return;
        }
    
    LogTo(BLIPVerbose,@"Close request accepted");
    _blipClosing = YES; // this prevents _beginClose from sending a close request back
    [self close];
}


@end




#pragma mark -
@implementation BLIPListener

- (id) init
{
    self = [super init];
    if (self != nil) {
        self.connectionClass = [BLIPConnection class];
    }
    return self;
}

- (void) dealloc
{
    [_dispatcher release];
    [super dealloc];
}

- (BLIPDispatcher*) dispatcher
{
    if( ! _dispatcher )
        _dispatcher = [[BLIPDispatcher alloc] init];
    return _dispatcher;
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
