//
//  TCPWriter.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "TCPWriter.h"
#import "TCP_Internal.h"

#import "Logging.h"
#import "Test.h"


@implementation TCPWriter


- (void) dealloc
{
    [_queue release];
    [_currentData release];
    [super dealloc];
}


- (TCPReader*) reader
{
    return _conn.reader;
}


- (BOOL) isBusy
{
    return _currentData || _queue.count > 0;
}


- (void) writeData: (NSData*)data
{
    if( !_queue )
        _queue = [[NSMutableArray alloc] init];
    [_queue addObject: data];
    if( _queue.count==1 && ((NSOutputStream*)_stream).hasSpaceAvailable )
        [self _canWrite];
}


- (void) _canWrite
{
    if( ! _currentData ) {
        if( _queue.count==0 ) {
            [self queueIsEmpty]; // this may call -writeData, which will call _canWrite again
            return;
        }
        _currentData = [[_queue objectAtIndex: 0] retain];
        _currentDataPos = 0;
        LogTo(TCPVerbose,@"%@ using _currentData %p (%u bytes)", self,_currentData,_currentData.length);
        [_queue removeObjectAtIndex: 0];
    }
    
    const uint8_t* src = _currentData.bytes;
    src += _currentDataPos;
    NSInteger len = _currentData.length - _currentDataPos;
    NSInteger written = [(NSOutputStream*)_stream write: src maxLength: len];
    if( written < 0 )
        [self _gotError];
    else if( written < len ) {
        LogTo(TCPVerbose,@"%@ wrote %i bytes (of %u) from %p", self,written,len,_currentData);
        _currentDataPos += written;
    } else {
        LogTo(TCPVerbose,@"%@ wrote %i bytes, released %p", self,written,_currentData);
        setObj(&_currentData,nil);
    }
}


- (void) queueIsEmpty
{
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
