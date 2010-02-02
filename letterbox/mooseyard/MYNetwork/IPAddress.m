//
//  IPAddress.m
//  MYNetwork
//
//  Created by Jens Alfke on 1/4/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "IPAddress.h"

#import "Logging.h"
#import "Test.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <net/if.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import <netdb.h>


@implementation IPAddress


+ (UInt32) IPv4FromDottedQuadString: (NSString*)str
{
    Assert(str);
    UInt32 ipv4 = 0;
    NSScanner *scanner = [NSScanner scannerWithString: str];
    for( int i=0; i<4; i++ ) {
        if( i>0 && ! [scanner scanString: @"." intoString: nil] )
            return 0;
        NSInteger octet;
        if( ! [scanner scanInteger: &octet] || octet<0 || octet>255 )
            return 0;
        ipv4 = (ipv4<<8) | octet;
    }
    if( ! [scanner isAtEnd] )
        return 0;
    return htonl(ipv4);
}
         
         
- (id) initWithHostname: (NSString*)hostname port: (UInt16)port
{
    Assert(hostname);
    self = [super init];
    if (self != nil) {
        _ipv4 = [[self class] IPv4FromDottedQuadString: hostname];
        if( ! _ipv4 ) {
            [self release];
            return [[HostAddress alloc] initWithHostname: hostname port: port];
        }
        _port = port;
    }
    return self;
}

+ (IPAddress*) addressWithHostname: (NSString*)hostname port: (UInt16)port
{
    return [[[self alloc] initWithHostname: hostname port: port] autorelease];
}


- (id) initWithIPv4: (UInt32)ipv4 port: (UInt16)port
{
    self = [super init];
    if (self != nil) {
        _ipv4 = ipv4;
        _port = port;
    }
    return self;
}

- (id) initWithIPv4: (UInt32)ipv4
{
    return [self initWithIPv4: ipv4 port: 0];
}

- (id) initWithSockAddr: (const struct sockaddr*)sockaddr
{
    if( sockaddr->sa_family == AF_INET ) {
        const struct sockaddr_in *addr_in = (const struct sockaddr_in*)sockaddr;
        return [self initWithIPv4: addr_in->sin_addr.s_addr port: ntohs(addr_in->sin_port)];
    } else {
        [self release];
        return nil;
    }
}

- (id) initWithSockAddr: (const struct sockaddr*)sockaddr
                   port: (UInt16)port
{
    self = [self initWithSockAddr: sockaddr];
    if (self)
        _port = port;
    return self;
}

- (id) initWithData: (NSData*)data
{
    if (!data) {
        [self release];
        return nil;
    }
    const struct sockaddr* addr = data.bytes;
    if (data.length < sizeof(struct sockaddr_in))
        addr = nil;
    return [self initWithSockAddr: addr];
}


+ (IPAddress*) addressOfSocket: (CFSocketNativeHandle)socket
{
    uint8_t name[SOCK_MAXADDRLEN];
    socklen_t namelen = sizeof(name);
    struct sockaddr *addr = (struct sockaddr*)name;
    if (0 == getpeername(socket, addr, &namelen))
        return [[[self alloc] initWithSockAddr: addr] autorelease];
    else
        return nil;
}    

- (id) copyWithZone: (NSZone*)zone
{
    return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if( _ipv4 )
        [coder encodeInt32: _ipv4 forKey: @"ipv4"];
    if( _port )
        [coder encodeInt: _port forKey: @"port"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if( self ) {
        _ipv4 = [decoder decodeInt32ForKey: @"ipv4"];
        _port = [decoder decodeIntForKey: @"port"];
    }
    return self;
}


@synthesize ipv4=_ipv4, port=_port;

- (BOOL) isEqual: (IPAddress*)addr
{
    return [addr isKindOfClass: [IPAddress class]] && [self isSameHost: addr] && addr->_port==_port;
}

- (BOOL) isSameHost: (IPAddress*)addr
{
    return addr && _ipv4==addr->_ipv4;
}

- (NSUInteger) hash
{
    return _ipv4 ^ _port;
}

- (NSString*) ipv4name
{
    UInt32 ipv4 = self.ipv4;
    if( ipv4 != 0 ) {
        const UInt8* b = (const UInt8*)&ipv4;
        return [NSString stringWithFormat: @"%u.%u.%u.%u",
                (unsigned)b[0],(unsigned)b[1],(unsigned)b[2],(unsigned)b[3]];
    } else
        return nil;
}

- (NSString*) hostname
{
    return [self ipv4name];
}

- (NSData*) asData
{
    struct sockaddr_in addr = {
        .sin_len    = sizeof(struct sockaddr_in),
        .sin_family = AF_INET,
        .sin_port   = htons(_port),
        .sin_addr   = {htonl(_ipv4)} };
    return [NSData dataWithBytes: &addr length: sizeof(addr)];
}

- (NSString*) description
{
    NSString *name = self.hostname ?: @"0.0.0.0";
    if( _port )
        name = [name stringByAppendingFormat: @":%hu",_port];
    return name;
}


+ (IPAddress*) localAddressWithPort: (UInt16)port
{
    // getifaddrs returns a linked list of interface entries;
    // find the first active non-loopback interface with IPv4:
    UInt32 address = 0;
    struct ifaddrs *interfaces;
    if( getifaddrs(&interfaces) == 0 ) {
        struct ifaddrs *interface;
        for( interface=interfaces; interface; interface=interface->ifa_next ) {
            if( (interface->ifa_flags & IFF_UP) && ! (interface->ifa_flags & IFF_LOOPBACK) ) {
                const struct sockaddr_in *addr = (const struct sockaddr_in*) interface->ifa_addr;
                if( addr && addr->sin_family==AF_INET ) {
                    address = addr->sin_addr.s_addr;
                    break;
                }
            }
        }
        freeifaddrs(interfaces);
    }
    return [[[self alloc] initWithIPv4: address port: port] autorelease];
}

+ (IPAddress*) localAddress
{
    return [self localAddressWithPort: 0];
}


// Private IP address ranges. See RFC 3330.
static const struct {UInt32 mask, value;} const kPrivateRanges[] = {
    {0xFF000000, 0x00000000},       //   0.x.x.x (hosts on "this" network)
    {0xFF000000, 0x0A000000},       //  10.x.x.x (private address range)
    {0xFF000000, 0x7F000000},       // 127.x.x.x (loopback)
    {0xFFFF0000, 0xA9FE0000},       // 169.254.x.x (link-local self-configured addresses)
    {0xFFF00000, 0xAC100000},       // 172.(16-31).x.x (private address range)
    {0xFFFF0000, 0xC0A80000},       // 192.168.x.x (private address range)
    {0,0}
};


- (BOOL) isPrivate
{
    UInt32 address = ntohl(self.ipv4);
    int i;
    for( i=0; kPrivateRanges[i].mask; i++ )
        if( (address & kPrivateRanges[i].mask) == kPrivateRanges[i].value )
            return YES;
    return NO;
}


@end





@implementation HostAddress


- (id) initWithHostname: (NSString*)hostname port: (UInt16)port
{
    self = [super initWithIPv4: 0 port: port];
    if( self ) {
        if( [hostname length]==0 ) {
            [self release];
            return nil;
        }
        _hostname = [hostname copy];
    }
    return self;
}

- (id) initWithHostname: (NSString*)hostname
               sockaddr: (const struct sockaddr*)sockaddr
                   port: (UInt16)port;
{
    if( [hostname length]==0 ) {
        [self release];
        return nil;
    }
    self = [super initWithSockAddr: sockaddr port: port];
    if( self ) {
        _hostname = [hostname copy];
    }
    return self;
}    


- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder: coder];
    [coder encodeObject: _hostname forKey: @"host"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if( self ) {
        _hostname = [[decoder decodeObjectForKey: @"host"] copy];
    }
    return self;
}

- (void)dealloc 
{
    [_hostname release];
    [super dealloc];
}


- (NSString*) description
{
    NSMutableString *desc = [[_hostname mutableCopy] autorelease];
    NSString *addr = self.ipv4name;
    if (addr)
        [desc appendFormat: @"(%@)", addr];
    if( self.port )
        [desc appendFormat: @":%hu",self.port];
    return desc;
}


- (NSUInteger) hash
{
    return [_hostname hash] ^ self.port;
}


- (NSString*) hostname  {return _hostname;}


- (UInt32) ipv4
{
    struct hostent *ent = gethostbyname(_hostname.UTF8String);
    if( ! ent ) {
        Log(@"HostAddress: DNS lookup failed for <%@>: %s", _hostname, hstrerror(h_errno));
        return 0;
    }
    return * (const in_addr_t*) ent->h_addr_list[0];
}


- (BOOL) isSameHost: (IPAddress*)addr
{
    return [addr isKindOfClass: [HostAddress class]] && [_hostname caseInsensitiveCompare: addr.hostname]==0;
}


@end




@implementation RecentAddress


- (id) initWithIPAddress: (IPAddress*)addr
{
    return [super initWithIPv4: addr.ipv4 port: addr.port];
}


@synthesize lastSuccess=_lastSuccess, successes=_successes;

- (BOOL) noteSuccess
{
    if( _successes < 0xFFFF )
        _successes++;
    _lastSuccess = CFAbsoluteTimeGetCurrent();
    return YES;
}

- (BOOL) noteSeen
{
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    BOOL significant = ( now-_lastSuccess >= 18*60*60 );
    _lastSuccess = now;
    return significant;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder: coder];
    [coder encodeDouble: _lastSuccess forKey: @"last"];
    [coder encodeInt: _successes forKey: @"succ"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if( self ) {
        _lastSuccess = [decoder decodeDoubleForKey: @"last"];
        _successes = [decoder decodeIntForKey: @"succ"];
    }
    return self;
}


@end





#import "Test.h"

TestCase(IPAddress) {
    RequireTestCase(CollectionUtils);
    IPAddress *addr = [[IPAddress alloc] initWithIPv4: htonl(0x0A0001FE) port: 8080];
    CAssertEq(addr.ipv4,(UInt32)htonl(0x0A0001FE));
    CAssertEq(addr.port,8080);
    CAssertEqual(addr.hostname,@"10.0.1.254");
    CAssertEqual(addr.description,@"10.0.1.254:8080");
    CAssert(addr.isPrivate);
	[addr release];
    
    addr = [[IPAddress alloc] initWithHostname: @"66.66.0.255" port: 123];
    CAssertEq(addr.class,[IPAddress class]);
    CAssertEq(addr.ipv4,(UInt32)htonl(0x424200FF));
    CAssertEq(addr.port,123);
    CAssertEqual(addr.hostname,@"66.66.0.255");
    CAssertEqual(addr.description,@"66.66.0.255:123");
    CAssert(!addr.isPrivate);
 	[addr release];
   
    addr = [[IPAddress alloc] initWithHostname: @"www.apple.com" port: 80];
    CAssertEq(addr.class,[HostAddress class]);
    Log(@"www.apple.com = %@ [0x%08X]", addr.ipv4name, ntohl(addr.ipv4));
    CAssertEq(addr.ipv4,(UInt32)htonl(0x11FBC820));
    CAssertEq(addr.port,80);
    CAssertEqual(addr.hostname,@"www.apple.com");
    CAssertEqual(addr.description,@"www.apple.com:80");
    CAssert(!addr.isPrivate);
	[addr release];
}


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
