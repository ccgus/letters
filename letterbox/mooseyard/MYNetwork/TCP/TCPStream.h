//
//  TCPStream.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TCPConnection, TCPWriter, IPAddress;


/** Abstract superclass for data streams, used by TCPConnection. */
@interface TCPStream : NSObject <NSStreamDelegate>
{
    TCPConnection *_conn;
    NSStream *_stream;
    BOOL _shouldClose;
}

- (id) initWithConnection: (TCPConnection*)conn stream: (NSStream*)stream;

/** The IP address this stream is connected to. */
@property (readonly) IPAddress *peerAddress;

/** The connection's security level as reported by the underlying CFStream. */
@property (readonly) NSString *securityLevel;

/** The SSL property dictionary for the CFStream. */
@property (copy) NSDictionary* SSLProperties;

/** The SSL certificate(s) of the peer, if any. */
@property (readonly) NSArray *peerSSLCerts;

/** Opens the stream. */
- (void) open;

/** Disconnects abruptly. */
- (void) disconnect;

/** Closes the stream politely, waiting until there's no data pending. */
- (BOOL) close;

/** Is the stream open? */
@property (readonly) BOOL isOpen;

/** Does the stream have pending data to read or write, that prevents it from closing? */
@property (readonly) BOOL isBusy;

/** Returns NO if the stream is ready to close (-close has been called and -isBusy is NO.) */
@property (readonly) BOOL isActive;

/** Generic accessor for CFStream/NSStream properties. */
- (id) propertyForKey: (CFStringRef)cfStreamProperty;

/** Generic accessor for CFStream/NSStream properties. */
- (void) setProperty: (id)value forKey: (CFStringRef)cfStreamProperty;

@end


/** Input stream for a TCPConnection. */
@interface TCPReader : TCPStream

/** The connection's TCPWriter. */
@property (readonly) TCPWriter *writer;

/** Reads bytes from the stream, like the corresponding method of NSInputStream.
    The number of bytes actually read is returned, or zero if no data is available.
    If an error occurs, it will call its -_gotError method, and return a negative number. */
- (NSInteger) read: (void*)dst maxLength: (NSUInteger)maxLength;

@end



@interface TCPStream (Protected)
/** Called when the stream opens. */
- (void) _opened;

/** Called when the stream has bytes available to read. */
- (void) _canRead;

/** Called when the stream has space available in its output buffer to write to. */
- (void) _canWrite;
 
/** Called when the underlying stream closes due to the socket closing. */
- (void) _gotEOF;

/** Call this if a read/write call returns -1 to report an error;
    it will look up the error from the NSStream and call gotError: with it.
    This method always returns NO, so you can "return [self _gotError]". */
- (BOOL) _gotError;

/** Signals a fatal error to the TCPConnection.
    This method always returns NO, so you can "return [self _gotError: e]". */
- (BOOL) _gotError: (NSError*)error;
@end
