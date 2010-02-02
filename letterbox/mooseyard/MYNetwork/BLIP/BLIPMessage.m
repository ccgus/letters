//
//  BLIPMessage.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPMessage.h"
#import "BLIP_Internal.h"
#import "BLIPReader.h"
#import "BLIPWriter.h"

#import "Logging.h"
#import "Test.h"
#import "ExceptionUtils.h"
#import "Target.h"

// From Google Toolbox For Mac <http://code.google.com/p/google-toolbox-for-mac/>
#import "GTMNSData+zlib.h"


@implementation BLIPMessage


- (id) _initWithConnection: (BLIPConnection*)connection
                    isMine: (BOOL)isMine
                     flags: (BLIPMessageFlags)flags
                    number: (UInt32)msgNo
                      body: (NSData*)body
{
    self = [super init];
    if (self != nil) {
        _connection = [connection retain];
        _isMine = isMine;
        _flags = flags;
        _number = msgNo;
        if( isMine ) {
            _body = body.copy;
            _properties = [[BLIPMutableProperties alloc] init];
            _propertiesAvailable = YES;
            _complete = YES;
        } else {
            _encodedBody = body.mutableCopy;
        }
        LogTo(BLIPVerbose,@"INIT %@",self);
    }
    return self;
}

- (void) dealloc
{
    LogTo(BLIPVerbose,@"DEALLOC %@",self);
    [_properties release];
    [_encodedBody release];
    [_mutableBody release];
    [_body release];
    [_connection release];
    [super dealloc];
}


- (NSString*) description
{
    NSUInteger length = (_body.length ?: _mutableBody.length) ?: _encodedBody.length;
    NSMutableString *desc = [NSMutableString stringWithFormat: @"%@[#%u, %u bytes",
                             self.class,_number, length];
    if( _flags & kBLIP_Compressed ) {
        if( _encodedBody && _encodedBody.length != length )
            [desc appendFormat: @" (%u gzipped)", _encodedBody.length];
        else
            [desc appendString: @", gzipped"];
    }
    if( _flags & kBLIP_Urgent )
        [desc appendString: @", urgent"];
    if( _flags & kBLIP_NoReply )
        [desc appendString: @", noreply"];
    if( _flags & kBLIP_Meta )
        [desc appendString: @", META"];
    [desc appendString: @"]"];
    return desc;
}

- (NSString*) descriptionWithProperties
{
    NSMutableString *desc = (NSMutableString*)self.description;
    [desc appendFormat: @" %@", self.properties.allProperties];
    return desc;
}


#pragma mark -
#pragma mark PROPERTIES & METADATA:


@synthesize connection=_connection, number=_number, isMine=_isMine, isMutable=_isMutable,
            _bytesWritten, sent=_sent, propertiesAvailable=_propertiesAvailable, complete=_complete,
            representedObject=_representedObject;


- (void) _setFlag: (BLIPMessageFlags)flag value: (BOOL)value
{
    Assert(_isMine && _isMutable);
    if( value )
        _flags |= flag;
    else
        _flags &= ~flag;
}

- (BLIPMessageFlags) _flags                 {return _flags;}

- (BOOL) compressed                         {return (_flags & kBLIP_Compressed) != 0;}
- (BOOL) urgent                             {return (_flags & kBLIP_Urgent) != 0;}
- (void) setCompressed: (BOOL)compressed    {[self _setFlag: kBLIP_Compressed value: compressed];}
- (void) setUrgent: (BOOL)high              {[self _setFlag: kBLIP_Urgent value: high];}


- (NSData*) body
{
    if( ! _body && _isMine )
        return [[_mutableBody copy] autorelease];
    else
        return _body;
}

- (void) setBody: (NSData*)body
{
    Assert(_isMine && _isMutable);
    if( _mutableBody )
        [_mutableBody setData: body];
    else
        _mutableBody = [body mutableCopy];
}

- (void) _addToBody: (NSData*)data
{
    if( data.length ) {
        if( _mutableBody )
            [_mutableBody appendData: data];
        else
            _mutableBody = [data mutableCopy];
        setObj(&_body,nil);
    }
}

- (void) addToBody: (NSData*)data
{
    Assert(_isMine && _isMutable);
    [self _addToBody: data];
}


- (NSString*) bodyString
{
    NSData *body = self.body;
    if( body )
        return [[[NSString alloc] initWithData: body encoding: NSUTF8StringEncoding] autorelease];
    else
        return nil;
}

- (void) setBodyString: (NSString*)string
{
    self.body = [string dataUsingEncoding: NSUTF8StringEncoding];
    self.contentType = @"text/plain; charset=UTF-8";
}


- (BLIPProperties*) properties
{
    return _properties;
}

- (BLIPMutableProperties*) mutableProperties
{
    Assert(_isMine && _isMutable);
    return (BLIPMutableProperties*)_properties;
}

- (NSString*) valueOfProperty: (NSString*)property
{
    return [_properties valueOfProperty: property];
}

- (void) setValue: (NSString*)value ofProperty: (NSString*)property
{
    [self.mutableProperties setValue: value ofProperty: property];
}

- (NSString*) contentType               {return [_properties valueOfProperty: @"Content-Type"];}
- (void) setContentType: (NSString*)t   {[self setValue: t ofProperty: @"Content-Type"];}
- (NSString*) profile                   {return [_properties valueOfProperty: @"Profile"];}
- (void) setProfile: (NSString*)p       {[self setValue: p ofProperty: @"Profile"];}


#pragma mark -
#pragma mark I/O:


- (void) _encode
{
    Assert(_isMine && _isMutable);
    _isMutable = NO;

    BLIPProperties *oldProps = _properties;
    _properties = [oldProps copy];
    [oldProps release];
    
    _encodedBody = [_properties.encodedData mutableCopy];
    Assert(_encodedBody.length>=2);

    NSData *body = _body ?: _mutableBody;
    NSUInteger length = body.length;
    if( length > 0 ) {
        if( self.compressed ) {
            body = [NSData gtm_dataByGzippingData: body compressionLevel: 5];
            LogTo(BLIPVerbose,@"Compressed %@ to %u bytes (%.0f%%)", self,body.length,
                  body.length*100.0/length);
        }
        [_encodedBody appendData: body];
    }
}


- (void) _assignedNumber: (UInt32)number
{
    Assert(_number==0,@"%@ has already been sent",self);
    _number = number;
    _isMutable = NO;
}


- (BOOL) _writeFrameTo: (BLIPWriter*)writer maxSize: (UInt16)maxSize
{
    Assert(_number!=0);
    Assert(_isMine);
    Assert(_encodedBody);
    if( _bytesWritten==0 )
        LogTo(BLIP,@"Now sending %@",self);
    ssize_t lengthToWrite = _encodedBody.length - _bytesWritten;
    if( lengthToWrite <= 0 && _bytesWritten > 0 )
        return NO; // done
    Assert(maxSize > sizeof(BLIPFrameHeader));
    maxSize -= sizeof(BLIPFrameHeader);
    UInt16 flags = _flags;
    if( lengthToWrite > maxSize ) {
        lengthToWrite = maxSize;
        flags |= kBLIP_MoreComing;
        LogTo(BLIPVerbose,@"%@ pushing frame, bytes %u-%u", self, _bytesWritten, _bytesWritten+lengthToWrite);
    } else {
        flags &= ~kBLIP_MoreComing;
        LogTo(BLIPVerbose,@"%@ pushing frame, bytes %u-%u (finished)", self, _bytesWritten, _bytesWritten+lengthToWrite);
    }
        
    // First write the frame header:
    BLIPFrameHeader header = {  NSSwapHostIntToBig(kBLIPFrameHeaderMagicNumber),
                                NSSwapHostIntToBig(_number),
                                NSSwapHostShortToBig(flags),
                                NSSwapHostShortToBig(sizeof(BLIPFrameHeader) + lengthToWrite) };
    
    [writer writeData: [NSData dataWithBytes: &header length: sizeof(header)]];
    
    // Then write the body:
    if( lengthToWrite > 0 ) {
        [writer writeData: [NSData dataWithBytes: (UInt8*)_encodedBody.bytes + _bytesWritten
                                          length: lengthToWrite]];
        _bytesWritten += lengthToWrite;
    }
    return (flags & kBLIP_MoreComing) != 0;
}


- (BOOL) _receivedFrameWithHeader: (const BLIPFrameHeader*)header body: (NSData*)body
{
    Assert(!_isMine);
    AssertEq(header->number,_number);
    Assert(_flags & kBLIP_MoreComing);
    
    BLIPMessageType frameType = (header->flags & kBLIP_TypeMask), curType = (_flags & kBLIP_TypeMask);
    if( frameType != curType ) {
        Assert(curType==kBLIP_RPY && frameType==kBLIP_ERR && _mutableBody.length==0,
               @"Incoming frame's type %i doesn't match %@",frameType,self);
        _flags = (_flags & ~kBLIP_TypeMask) | frameType;
    }

    if( _encodedBody )
        [_encodedBody appendData: body];
    else
        _encodedBody = [body mutableCopy];
    LogTo(BLIPVerbose,@"%@ rcvd bytes %u-%u", self, _encodedBody.length-body.length, _encodedBody.length);
    
    if( ! _properties ) {
        // Try to extract the properties:
        ssize_t usedLength;
        setObj(&_properties, [BLIPProperties propertiesWithEncodedData: _encodedBody usedLength: &usedLength]);
        if( _properties ) {
            [_encodedBody replaceBytesInRange: NSMakeRange(0,usedLength)
                                    withBytes: NULL length: 0];
        } else if( usedLength < 0 )
            return NO;
        self.propertiesAvailable = YES;
    }
    
    if( ! (header->flags & kBLIP_MoreComing) ) {
        // After last frame, decode the data:
        _flags &= ~kBLIP_MoreComing;
        if( ! _properties )
            return NO;
        unsigned encodedLength = _encodedBody.length;
        if( self.compressed && encodedLength>0 ) {
            _body = [[NSData gtm_dataByInflatingData: _encodedBody] copy];
            if( ! _body )
                return NO;
            LogTo(BLIPVerbose,@"Uncompressed %@ from %u bytes (%.1fx)", self, encodedLength,
                  _body.length/(float)encodedLength);
        } else {
            _body = [_encodedBody copy];
        }
        setObj(&_encodedBody,nil);
        self.propertiesAvailable = self.complete = YES;
    }
    return YES;
}


- (void) _connectionClosed
{
    if( _isMine ) {
        _bytesWritten = 0;
        _flags |= kBLIP_MoreComing;
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
