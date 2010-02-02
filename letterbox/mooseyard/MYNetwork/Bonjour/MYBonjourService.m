//
//  MYBonjourService.m
//  MYNetwork
//
//  Created by Jens Alfke on 1/22/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYBonjourService.h"
#import "MYBonjourQuery.h"
#import "MYAddressLookup.h"
#import "IPAddress.h"
#import "ConcurrentOperation.h"
#import "Test.h"
#import "Logging.h"
#import "ExceptionUtils.h"
#import <dns_sd.h>


NSString* const kBonjourServiceResolvedAddressesNotification = @"BonjourServiceResolvedAddresses";


@interface MYBonjourService ()
@property (copy) NSString *hostname;
@property UInt16 port;
@end


@implementation MYBonjourService


- (id) initWithBrowser: (MYBonjourBrowser*)browser
                  name: (NSString*)serviceName
                  type: (NSString*)type
                domain: (NSString*)domain
             interface: (UInt32)interfaceIndex
{
    Assert(serviceName);
    Assert(type);
    Assert(domain);
    self = [super init];
    if (self != nil) {
        _bonjourBrowser = browser;
        _name = [serviceName copy];
        _type = [type copy];
        _domain = [domain copy];
        _fullName = [[[self class] fullNameOfService: _name ofType: _type inDomain: _domain] retain];
        _interfaceIndex = interfaceIndex;
    }
    return self;
}

- (void) dealloc {
    [_txtQuery stop];
    [_txtQuery release];
    [_addressLookup stop];
    [_addressLookup release];
    [_name release];
    [_type release];
    [_domain release];
    [_fullName release];
    [_hostname release];
    [super dealloc];
}


@synthesize bonjourBrowser=_bonjourBrowser, name=_name, type=_type, domain=_domain, 
            fullName=_fullName, interfaceIndex=_interfaceIndex;


- (NSString*) description {
    return $sprintf(@"%@[%@]", self.class,self.fullName);
}


- (NSComparisonResult) compare: (id)obj {
    return [_name caseInsensitiveCompare: [obj name]];
}

- (BOOL) isEqual: (id)obj {
    if ([obj isKindOfClass: [MYBonjourService class]]) {
        MYBonjourService *service = obj;
        return [_name caseInsensitiveCompare: [service name]] == 0
            && $equal(_type, service->_type)
            && $equal(_domain, service->_domain)
            && _interfaceIndex == service->_interfaceIndex;
    } else {
        return NO;
    }
}

- (NSUInteger) hash {
    return _name.hash ^ _type.hash ^ _domain.hash;
}


- (void) added {
    LogTo(Bonjour,@"Added %@",self);
}

- (void) removed {
    LogTo(Bonjour,@"Removed %@",self);
    [self stop];
    
    [_txtQuery stop];
    [_txtQuery release];
    _txtQuery = nil;
    
    [_addressLookup stop];
}


- (void)setHostname:(NSString *)value {
    if (_hostname != value) {
        [_hostname release];
        _hostname = [value retain];
    }
}



- (NSString*) hostname {
    if (!_startedResolve )
        [self start];
    return _hostname;
}

- (void)setPort:(UInt16)value {
    _port = value;
}



- (UInt16) port {
    if (!_startedResolve )
        [self start];
    return _port;
}


#pragma mark -
#pragma mark TXT RECORD:


- (NSDictionary*) txtRecord {
    if (!_txtQuery) {
        _txtQuery = [[MYBonjourQuery alloc] initWithBonjourService: self 
                                                        recordType: kDNSServiceType_TXT];
        _txtQuery.continuous = YES;
        [_txtQuery start];
    }
    return _txtRecord;
}

- (void) txtRecordChanged {
    // no-op (this is here for subclassers to override)
}

- (NSString*) txtStringForKey: (NSString*)key {
    NSData *value = [self.txtRecord objectForKey: key];
    if( ! value )
        return nil;
    if( ! [value isKindOfClass: [NSData class]] ) {
        Warn(@"TXT dictionary has unexpected value type: %@",value.class);
        return nil;
    }
    NSString *str = [[NSString alloc] initWithData: value encoding: NSUTF8StringEncoding];
    if( ! str )
        str = [[NSString alloc] initWithData: value encoding: NSWindowsCP1252StringEncoding];
    return [str autorelease];
}

- (void) setTxtData: (NSData*)txtData {
    NSDictionary *txtRecord = txtData ?[NSNetService dictionaryFromTXTRecordData: txtData] :nil;
    if (!$equal(txtRecord,_txtRecord)) {
        LogTo(Bonjour,@"%@ TXT = %@", self,txtRecord);
        [self willChangeValueForKey: @"txtRecord"];
        setObj(&_txtRecord, txtRecord);
        [self didChangeValueForKey: @"txtRecord"];
        [self txtRecordChanged];
    }
}


- (void) queryDidUpdate: (MYBonjourQuery*)query {
    if (query==_txtQuery)
        [self setTxtData: query.recordData];
}


#pragma mark -
#pragma mark HOSTNAME/PORT RESOLUTION:


- (void) priv_resolvedHostname: (NSString*)hostname
                          port: (uint16_t)port
                     txtRecord: (NSData*)txtData
{
    LogTo(Bonjour, @"%@: hostname=%@, port=%u, txt=%u bytes", 
          self, hostname, port, txtData.length);

    if (port!=_port || !$equal(hostname,_hostname)) {
        self.hostname = hostname;
        self.port = port;
    }
    
    [self setTxtData: txtData];
}

- (void) gotResponse: (DNSServiceErrorType)errorCode {
    [super gotResponse: errorCode];
    [_addressLookup _serviceGotResponse];
}


static void resolveCallback(DNSServiceRef                       sdRef,
                            DNSServiceFlags                     flags,
                            uint32_t                            interfaceIndex,
                            DNSServiceErrorType                 errorCode,
                            const char                          *fullname,
                            const char                          *hosttarget,
                            uint16_t                            port,
                            uint16_t                            txtLen,
                            const unsigned char                 *txtRecord,
                            void                                *context)
{
    MYBonjourService *service = context;
    @try{
        //LogTo(Bonjour, @"resolveCallback for %@ (err=%i)", service,errorCode);
        if (!errorCode) {
            NSData *txtData = nil;
            if (txtRecord)
                txtData = [NSData dataWithBytes: txtRecord length: txtLen];
            [service priv_resolvedHostname: [NSString stringWithUTF8String: hosttarget]
                                      port: ntohs(port)
                                 txtRecord: txtData];
        }
    }catchAndReport(@"MYBonjourResolver query callback");
    [service gotResponse: errorCode];
}


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    _startedResolve = YES;
    return DNSServiceResolve(sdRefPtr,
                             kDNSServiceFlagsShareConnection,
                             _interfaceIndex, 
                             _name.UTF8String, _type.UTF8String, _domain.UTF8String,
                             &resolveCallback, self);
}


- (MYAddressLookup*) addressLookup {
    if (!_addressLookup) {
        // Create the lookup the first time this is called:
        _addressLookup = [[MYAddressLookup alloc] _initWithBonjourService: self];
        _addressLookup.interfaceIndex = _interfaceIndex;
    }
    // (Re)start the lookup if it's expired:
    if (_addressLookup && _addressLookup.timeToLive <= 0.0)
        [_addressLookup start];
    return _addressLookup;
}


- (MYBonjourQuery*) queryForRecord: (UInt16)recordType {
    MYBonjourQuery *query = [[[MYBonjourQuery alloc] initWithBonjourService: self recordType: recordType]
                                 autorelease];
    return [query start] ?query :nil;
}


@end



/*
 Copyright (c) 2008-2009, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
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
