//
//  BLIPRequest.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/22/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPRequest.h"
#import "BLIP_Internal.h"
#import "BLIPWriter.h"
#import "BLIPReader.h"

#import "Target.h"
#import "Logging.h"
#import "Test.h"
#import "ExceptionUtils.h"


@implementation BLIPRequest


- (id) _initWithConnection: (BLIPConnection*)connection
                      body: (NSData*)body 
                properties: (NSDictionary*)properties
{
    self = [self _initWithConnection: connection
                              isMine: YES
                               flags: kBLIP_MSG
                              number: 0
                                body: body];
    if( self ) {
        _isMutable = YES;
        if( body )
            self.body = body;
        if( properties )
            [self.mutableProperties setAllProperties: properties];
    }
    return self;
}

+ (BLIPRequest*) requestWithBody: (NSData*)body
{
    return [[[self alloc] _initWithConnection: nil body: body properties: nil] autorelease];
}

+ (BLIPRequest*) requestWithBodyString: (NSString*)bodyString {
    return [self requestWithBody: [bodyString dataUsingEncoding: NSUTF8StringEncoding]];
}

+ (BLIPRequest*) requestWithBody: (NSData*)body
                      properties: (NSDictionary*)properties
{
    return [[[self alloc] _initWithConnection: nil body: body properties: properties] autorelease];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    Assert(self.complete);
    BLIPRequest *copy = [[self class] requestWithBody: self.body 
                                           properties: self.properties.allProperties];
    copy.compressed = self.compressed;
    copy.urgent = self.urgent;
    copy.noReply = self.noReply;
    return [copy retain];
}


- (void) dealloc
{
    [_response release];
    [super dealloc];
}


- (BOOL) noReply                            {return (_flags & kBLIP_NoReply) != 0;}
- (void) setNoReply: (BOOL)noReply          {[self _setFlag: kBLIP_NoReply value: noReply];}
- (BLIPConnection*) connection              {return _connection;}

- (void) setConnection: (BLIPConnection*)conn
{
    Assert(_isMine && !_sent,@"Connection can only be set before sending");
    setObj(&_connection,conn);
}


- (BLIPResponse*) send
{
    Assert(_connection,@"%@ has no connection to send over",self);
    Assert(!_sent,@"%@ was already sent",self);
    [self _encode];
    BLIPResponse *response = self.response;
    if( [(BLIPWriter*)_connection.writer sendRequest: self response: response] )
        self.sent = YES;
    else
        response = nil;
    return response;
}


- (BLIPResponse*) response
{
    if( ! _response && ! self.noReply )
        _response = [[BLIPResponse alloc] _initWithRequest: self];
    return _response;
}

- (void) deferResponse
{
    // This will allocate _response, causing -repliedTo to become YES, so BLIPConnection won't
    // send an automatic empty response after the current request handler returns.
    LogTo(BLIP,@"Deferring response to %@",self);
    [self response];
}

- (BOOL) repliedTo
{
    return _response != nil;
}

- (void) respondWithData: (NSData*)data contentType: (NSString*)contentType
{
    BLIPResponse *response = self.response;
    response.body = data;
    response.contentType = contentType;
    [response send];
}

- (void) respondWithString: (NSString*)string
{
    [self respondWithData: [string dataUsingEncoding: NSUTF8StringEncoding]
              contentType: @"text/plain; charset=UTF-8"];
}

- (void) respondWithError: (NSError*)error
{
    self.response.error = error; 
    [self.response send];
}

- (void) respondWithErrorCode: (int)errorCode message: (NSString*)errorMessage
{
    [self respondWithError: BLIPMakeError(errorCode, @"%@",errorMessage)];
}

- (void) respondWithException: (NSException*)exception
{
    [self respondWithError: BLIPMakeError(kBLIPError_HandlerFailed, @"%@", exception.reason)];
}


@end




#pragma mark -
@implementation BLIPResponse

- (id) _initWithRequest: (BLIPRequest*)request
{
    Assert(request);
    self = [super _initWithConnection: request.connection
                               isMine: !request.isMine
                                flags: kBLIP_RPY | kBLIP_MoreComing
                               number: request.number
                                 body: nil];
    if (self != nil) {
        if( _isMine ) {
            _isMutable = YES;
            if( request.urgent )
                _flags |= kBLIP_Urgent;
        } else {
            _flags |= kBLIP_MoreComing;
        }
    }
    return self;
}

- (void) dealloc
{
    [_error release];
    [_onComplete release];
    [super dealloc];
}


- (NSError*) error
{
    if( ! (_flags & kBLIP_ERR) )
        return nil;
    
    NSMutableDictionary *userInfo = [[[self.properties allProperties] mutableCopy] autorelease];
    NSString *domain = [userInfo objectForKey: @"Error-Domain"];
    int code = [[userInfo objectForKey: @"Error-Code"] intValue];
    if( domain==nil || code==0 ) {
        domain = BLIPErrorDomain;
        if( code==0 )
            code = kBLIPError_Unspecified;
    }
    [userInfo removeObjectForKey: @"Error-Domain"];
    [userInfo removeObjectForKey: @"Error-Code"];
    return [NSError errorWithDomain: domain code: code userInfo: userInfo];
}

- (void) _setError: (NSError*)error
{
    _flags &= ~kBLIP_TypeMask;
    if( error ) {
        // Setting this stuff is a PITA because this object might be technically immutable,
        // in which case the standard setters would barf if I called them.
        _flags |= kBLIP_ERR;
        setObj(&_body,nil);
        setObj(&_mutableBody,nil);
        
        BLIPMutableProperties *errorProps = [self.properties mutableCopy];
        if( ! errorProps )
            errorProps = [[BLIPMutableProperties alloc] init];
        NSDictionary *userInfo = error.userInfo;
        for( NSString *key in userInfo ) {
            id value = $castIf(NSString,[userInfo objectForKey: key]);
            if( value )
                [errorProps setValue: value ofProperty: key];
        }
        [errorProps setValue: error.domain ofProperty: @"Error-Domain"];
        [errorProps setValue: $sprintf(@"%i",error.code) ofProperty: @"Error-Code"];
        setObj(&_properties,errorProps);
        [errorProps release];
        
    } else {
        _flags |= kBLIP_RPY;
        [self.mutableProperties setAllProperties: nil];
    }
}

- (void) setError: (NSError*)error
{
    Assert(_isMine && _isMutable);
    [self _setError: error];
}


- (BOOL) send
{
    Assert(_connection,@"%@ has no connection to send over",self);
    Assert(!_sent,@"%@ was already sent",self);
    BLIPWriter *writer = (BLIPWriter*)_connection.writer;
    Assert(writer,@"%@'s connection has no writer (already closed?)",self);
    [self _encode];
    BOOL sent = self.sent = [writer sendMessage: self];
    Assert(sent);
    return sent;
}


@synthesize onComplete=_onComplete;


- (void) setComplete: (BOOL)complete
{
    [super setComplete: complete];
    if( complete && _onComplete ) {
        @try{
            [_onComplete invokeWithSender: self];
        }catchAndReport(@"BLIPRequest onComplete target");
    }
}


- (void) _connectionClosed
{
    [super _connectionClosed];
    if( !_isMine && !_complete ) {
        NSError *error = _connection.error;
        if (!error)
            error = BLIPMakeError(kBLIPError_Disconnected,
                                  @"Connection closed before response was received");
        // Change incoming response to an error:
        _isMutable = YES;
        [_properties autorelease];
        _properties = [_properties mutableCopy];
        [self _setError: error];
        _isMutable = NO;
        
        self.complete = YES;    // Calls onComplete target
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
