//  PortMapperTest.m
//  MYNetwork
//
//  Created by Jens Alfke on 1/4/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//



#import "MYPortMapper.h"
#import "IPAddress.h"
#import "Test.h"
#import "Logging.h"

#if DEBUG


/** A trivial class that just demonstrates how to create a MYPortMapper and listen for changes. */
@interface MYPortMapperTest : NSObject
{
    MYPortMapper *_mapper;
}

@end


@implementation MYPortMapperTest


- (id) init
{
    self = [super init];
    if( self ) {
        // Create MYPortMapper. This example doesn't open a real socket; just pretend that there's
        // already a TCP socket listening on port 8080. To experiment, you could turn on Web
        // Sharing, then change this port number to 80 -- that will make your computer's local
        // Apache web server reachable from the outside world while this program is running.
        _mapper = [[MYPortMapper alloc] initWithLocalPort: 80];
        
        // Optionally, request a public port number.
        // The NAT is free to ignore this and return a random number instead.
        _mapper.desiredPublicPort = 22222;
        
        // Now open the mapping (asynchronously):
        if( [_mapper start] ) {
            Log(@"Opening port mapping...");
            // Now listen for notifications to find out when the mapping opens, fails, or changes:
            [[NSNotificationCenter defaultCenter] addObserver: self 
                                                     selector: @selector(portMappingChanged:) 
                                                         name: MYPortMapperChangedNotification 
                                                       object: _mapper];
        } else {
            // MYPortMapper failed -- this is unlikely, but be graceful:
            Log(@"!! Error: MYPortMapper wouldn't start: %i",_mapper.error);
            [self release];
            return nil;
        }
    }
    return self;
}


- (void) portMappingChanged: (NSNotification*)n
{
    // This is where we get notified that the mapping was created, or that no mapping exists,
    // or that mapping failed.
    if( _mapper.error )
        Log(@"!! MYPortMapper error %i", _mapper.error);
    else {
        NSString *message = @"";
        if( !_mapper.isMapped )
            message = @" (no address translation!)";
        Log(@"** Public address:port is %@%@", _mapper.publicAddress, message);
        Log(@"    local address:port is %@", _mapper.localAddress);
    }
}


- (void) dealloc
{
    [_mapper stop];
    [_mapper release];
    [super dealloc];
}


@end



TestCase(MYPortMapper) {
    
    EnableLogTo(DNS,YES);
    EnableLogTo(PortMapper,YES);
    
    // Here's how to simply obtain your local and public address(es):
    IPAddress *addr = [IPAddress localAddress];
    Log(@"** Local address is %@%@ ...getting public addr...", 
        addr, (addr.isPrivate ?@" (private)" :@""));
    addr = [MYPortMapper findPublicAddress];
    Log(@"** Public address is %@", addr);

    // Start up the test class to create a mapping:
    MYPortMapperTest *test = [[MYPortMapperTest alloc] init];
    
    // Now let the runloop run forever...
    Log(@"Running the runloop forever...");
    [[NSRunLoop currentRunLoop] run];
        
    [test release];
}

#endif 

