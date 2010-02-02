//
//  TCPWriter.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "TCPStream.h"


/** Output stream for a TCPConnection. Writes a queue of arbitrary data blobs to the socket. */
@interface TCPWriter : TCPStream 
{
    NSMutableArray *_queue;
    NSData *_currentData;
    SInt32 _currentDataPos;
}

/** The connection's TCPReader. */
@property (readonly) TCPReader *reader;

/** Schedules data to be written to the socket.
    Always returns immediately; the bytes won't actually be sent until there's room. */
- (void) writeData: (NSData*)data;

//protected:

/** Will be called when the internal queue of data to be written is empty.
    Subclasses should override this and call -writeData: to refill the queue,
    if possible. */
- (void) queueIsEmpty;

@end
