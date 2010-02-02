//
//  BLIPReader.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPReader.h"
#import "BLIP_Internal.h"
#import "BLIPWriter.h"
#import "BLIPDispatcher.h"

#import "Logging.h"
#import "Test.h"
#import "CollectionUtils.h"


@interface BLIPReader ()
- (BOOL) _receivedFrameWithHeader: (const BLIPFrameHeader*)header body: (NSData*)body;
@end


@implementation BLIPReader


#define _blipConn ((BLIPConnection*)_conn)


- (id) initWithConnection: (BLIPConnection*)conn stream: (NSStream*)stream
{
    self = [super initWithConnection: conn stream: stream];
    if (self != nil) {
        _pendingRequests = [[NSMutableDictionary alloc] init];
        _pendingResponses = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [_pendingRequests release];
    [_pendingResponses release];
    [_curBody release];
    [super dealloc];
}

- (void) disconnect
{
    for( BLIPResponse *response in [_pendingResponses allValues] ) {
        [response _connectionClosed];
        [_conn tellDelegate: @selector(connection:receivedResponse:) withObject: response];
    }
    setObj(&_pendingResponses,nil);
    [super disconnect];
}


#pragma mark -
#pragma mark READING FRAMES:


- (NSString*) _validateHeader
{
    // Convert header to native byte order:
    _curHeader.magic = NSSwapBigIntToHost(_curHeader.magic);
    _curHeader.number= NSSwapBigIntToHost(_curHeader.number);
    _curHeader.flags = NSSwapBigShortToHost(_curHeader.flags);
    _curHeader.size  = NSSwapBigShortToHost(_curHeader.size);
    
    if( _curHeader.magic != kBLIPFrameHeaderMagicNumber )
        return $sprintf(@"Incorrect magic number (%08X not %08X)",
                        _curHeader.magic,kBLIPFrameHeaderMagicNumber);
    size_t bodyLength = _curHeader.size;
    if( bodyLength < sizeof(BLIPFrameHeader) )
        return @"Length is impossibly short";
    bodyLength -= sizeof(BLIPFrameHeader);
    _curBody = [[NSMutableData alloc] initWithLength: bodyLength];
    return nil;
}
    

- (void) _endCurFrame
{
    [self retain];
    [self _receivedFrameWithHeader: &_curHeader body: _curBody];
    memset(&_curHeader,0,sizeof(_curHeader));
    setObj(&_curBody,nil);
    _curBytesRead = 0;
    [self release];
}


- (BOOL) isBusy
{
    return _curBytesRead > 0 || _pendingRequests.count > 0 || _pendingResponses.count > 0;
}


- (void) _canRead
{
    SInt32 headerLeft = sizeof(BLIPFrameHeader) - _curBytesRead;
    if( headerLeft > 0 ) {
        // Read (more of) the header:
        NSInteger bytesRead = [self read: (uint8_t*)&_curHeader +_curBytesRead
                               maxLength: headerLeft];
        if( bytesRead > 0 ) {
            _curBytesRead += bytesRead;
            if( _curBytesRead < sizeof(BLIPFrameHeader) ) {
                // Incomplete header:
                LogTo(BLIPVerbose,@"%@ read %u bytes of header (%u left)",
                      self,bytesRead,sizeof(BLIPFrameHeader)-_curBytesRead);
            } else {
                // Finished reading the header!
                NSString *err = [self _validateHeader];
                if( err ) {
                    Warn(@"%@ read bogus frame header: %@",self,err);
                    return (void)[self _gotError: BLIPMakeError(kBLIPError_BadData, @"%@", err)];
                }
                LogTo(BLIPVerbose,@"%@: Read header; next is %u-byte body",self,_curBody.length);
                
                if( _curBody.length == 0 ) {
                    // Zero-byte body, so no need to wait for another read
                    [self _endCurFrame];
                }
            }
        }
        
    } else {
        // Read (more of) the current frame's body:
        SInt32 bodyRemaining = (SInt32)_curBody.length + headerLeft;
        if( bodyRemaining > 0 ) {
            uint8_t *dst = _curBody.mutableBytes;
            dst += _curBody.length - bodyRemaining;
            NSInteger bytesRead = [self read: dst maxLength: bodyRemaining];
            if( bytesRead > 0 ) {
                _curBytesRead += bytesRead;
                bodyRemaining -= bytesRead;
                LogTo(BLIPVerbose,@"%@: Read %u bytes of frame body (%u left)",self,bytesRead,bodyRemaining);
            }
        }
        if( bodyRemaining==0 ) {
            // Done reading this frame: give it to the Connection and reset my state
            [self _endCurFrame];
        }
    }
}


#pragma mark -
#pragma mark PROCESSING FRAMES:


- (void) _addPendingResponse: (BLIPResponse*)response
{
    [_pendingResponses setObject: response forKey: $object(response.number)];
}


- (BOOL) _receivedFrameWithHeader: (const BLIPFrameHeader*)header body: (NSData*)body
{
    static const char* kTypeStrs[16] = {"MSG","RPY","ERR","3??","4??","5??","6??","7??"};
    BLIPMessageType type = header->flags & kBLIP_TypeMask;
    LogTo(BLIPVerbose,@"%@ rcvd frame of %s #%u, length %u",self,kTypeStrs[type],header->number,body.length);

    id key = $object(header->number);
    BOOL complete = ! (header->flags & kBLIP_MoreComing);
    switch(type) {
        case kBLIP_MSG: {
            // Incoming request:
            BLIPRequest *request = [_pendingRequests objectForKey: key];
            if( request ) {
                // Continuation frame of a request:
                if( complete ) {
                    [[request retain] autorelease];
                    [_pendingRequests removeObjectForKey: key];
                }
            } else if( header->number == _numRequestsReceived+1 ) {
                // Next new request:
                request = [[[BLIPRequest alloc] _initWithConnection: _blipConn
                                                         isMine: NO
                                                          flags: header->flags | kBLIP_MoreComing
                                                         number: header->number
                                                           body: nil]
                                autorelease];
                if( ! complete )
                    [_pendingRequests setObject: request forKey: key];
                _numRequestsReceived++;
            } else
                return [self _gotError: BLIPMakeError(kBLIPError_BadFrame, 
                                               @"Received bad request frame #%u (next is #%u)",
                                               header->number,_numRequestsReceived+1)];
            
            if( ! [request _receivedFrameWithHeader: header body: body] )
                return [self _gotError: BLIPMakeError(kBLIPError_BadFrame, 
                                               @"Couldn't parse message frame")];
            
            if( complete )
                [_blipConn _dispatchRequest: request];
            break;
        }
            
        case kBLIP_RPY:
        case kBLIP_ERR: {
            BLIPResponse *response = [_pendingResponses objectForKey: key];
            if( response ) {
                if( complete ) {
                    [[response retain] autorelease];
                    [_pendingResponses removeObjectForKey: key];
                }
                
                if( ! [response _receivedFrameWithHeader: header body: body] ) {
                    return [self _gotError: BLIPMakeError(kBLIPError_BadFrame, 
                                                          @"Couldn't parse response frame")];
                } else if( complete ) 
                    [_blipConn _dispatchResponse: response];
                
            } else {
                if( header->number <= ((BLIPWriter*)self.writer).numRequestsSent )
                    LogTo(BLIP,@"??? %@ got unexpected response frame to my msg #%u",
                          self,header->number); //benign
                else
                    return [self _gotError: BLIPMakeError(kBLIPError_BadFrame, 
                                                          @"Bogus message number %u in response",
                                                          header->number)];
            }
            break;
        }
            
        default:
            // To leave room for future expansion, undefined message types are just ignored.
            Log(@"??? %@ received header with unknown message type %i", self,type);
            break;
    }
    return YES;
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
