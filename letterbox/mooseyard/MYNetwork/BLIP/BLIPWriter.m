//
//  BLIPFrameWriter.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/18/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPReader.h"
#import "BLIPWriter.h"
#import "BLIP_Internal.h"

#import "Logging.h"
#import "Test.h"


#define kDefaultFrameSize 4096


@implementation BLIPWriter


- (void) dealloc
{
    [_outBox release];
    [super dealloc];
}

- (void) disconnect
{
    [_outBox makeObjectsPerformSelector: @selector(_connectionClosed) withObject: nil];
    setObj(&_outBox,nil);
    [super disconnect];
}

@synthesize numRequestsSent=_numRequestsSent;


- (BOOL) isBusy
{
    return _outBox.count>0 || [super isBusy];
}


- (void) _queueMessage: (BLIPMessage*)msg isNew: (BOOL)isNew
{
    int n = _outBox.count, index;
    if( msg.urgent && n > 1 ) {
        // High-priority gets queued after the last existing high-priority message,
        // leaving one regular-priority message in between if possible.
        for( index=n-1; index>0; index-- ) {
            BLIPMessage *otherMsg = [_outBox objectAtIndex: index];
            if( [otherMsg urgent] ) {
                index = MIN(index+2, n);
                break;
            } else if( isNew && otherMsg._bytesWritten==0 ) {
                // But have to keep message starts in order
                index = index+1;
                break;
            }
        }
        if( index==0 )
            index = 1;
    } else {
        // Regular priority goes at the end of the queue:
        index = n;
    }
    if( ! _outBox )
        _outBox = [[NSMutableArray alloc] init];
    [_outBox insertObject: msg atIndex: index];
    
    if( isNew ) {
        LogTo(BLIP,@"%@ queuing outgoing %@ at index %i",self,msg,index);
        if( n==0 )
            [self queueIsEmpty];
    }
}


- (BOOL) sendMessage: (BLIPMessage*)message
{
    Assert(!message.sent,@"message has already been sent");
    [self _queueMessage: message isNew: YES];
    return YES;
}


- (BOOL) sendRequest: (BLIPRequest*)q response: (BLIPResponse*)response
{
    if( _shouldClose ) {
        Warn(@"%@: Attempt to send a request after the connection has started closing: %@",self,q);
        return NO;
    }
    [q _assignedNumber: ++_numRequestsSent];
    if( response ) {
        [response _assignedNumber: _numRequestsSent];
        [(BLIPReader*)self.reader _addPendingResponse: response];
    }
    return [self sendMessage: q];
}


- (void) queueIsEmpty
{
    if( _outBox.count > 0 ) {
        // Pop first message in queue:
        BLIPMessage *msg = [[_outBox objectAtIndex: 0] retain];
        [_outBox removeObjectAtIndex: 0];
        
        // As an optimization, allow message to send a big frame unless there's a higher-priority
        // message right behind it:
        size_t frameSize = kDefaultFrameSize;
        if( msg.urgent || _outBox.count==0 || ! [[_outBox objectAtIndex: 0] urgent] )
            frameSize *= 4;
        
        if( [msg _writeFrameTo: self maxSize: frameSize] ) {
            // add it back so it can send its next frame later:
            [self _queueMessage: msg isNew: NO];
        }
        [msg release];
    } else {
        LogTo(BLIPVerbose,@"%@: no more work for writer",self);
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
