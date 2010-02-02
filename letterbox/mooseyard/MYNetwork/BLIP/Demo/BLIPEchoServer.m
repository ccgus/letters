//
//  BLIPEchoServer.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPEchoServer.h"
#import "MYNetwork.h"


@implementation BLIPEchoServer


- (id) init
{
    self = [super init];
    if (self != nil) {
        _listener = [[BLIPListener alloc] initWithPort: 12345];
        _listener.delegate = self;
        _listener.pickAvailablePort = YES;
        _listener.bonjourServiceType = @"_blipecho._tcp";
        [_listener open];
        NSLog(@"%@ is listening...",self);
    }
    return self;
}

- (void) dealloc
{
    [_listener close];
    [_listener release];
    [super dealloc];
}

- (void) listener: (TCPListener*)listener failedToOpen: (NSError*)error
{
    NSLog(@"** %@ failed to open: %@",self,error);
}

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection
{
    NSLog(@"** %@ accepted %@",self,connection);
    connection.delegate = self;
}

- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    NSLog(@"** %@ failedToOpen: %@",connection,error);
}

- (BOOL) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    NSLog(@"***** %@ received %@",connection,request);
    [request respondWithData: request.body contentType: request.contentType];
    return YES;
}


@end


int main( int argc, const char **argv )
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    BLIPEchoServer *listener = [[BLIPEchoServer alloc] init];
    [[NSRunLoop currentRunLoop] run];
    [listener release];
    [pool drain];
}
