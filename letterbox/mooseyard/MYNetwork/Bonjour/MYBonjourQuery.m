//
//  MYBonjourQuery.m
//  MYNetwork
//
//  Created by Jens Alfke on 4/24/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYBonjourQuery.h"
#import "MYBonjourService.h"
#import "Test.h"
#import "Logging.h"
#import "ExceptionUtils.h"
#import <dns_sd.h>


static NSString* kRecordTypeNames[] = {
    @"0",
    @"A", //         = 1,      /* Host address. */
    @"NS", //        = 2,      /* Authoritative server. */
    @"MD", //        = 3,      /* Mail destination. */
    @"MF", //        = 4,      /* Mail forwarder. */
    @"CNAME", //     = 5,      /* Canonical name. */
    @"SOA", //       = 6,      /* Start of authority zone. */
    @"MB", //        = 7,      /* Mailbox domain name. */
    @"MG", //        = 8,      /* Mail group member. */
    @"MR", //        = 9,      /* Mail rename name. */
    @"NULL", //      = 10,     /* Null resource record. */
    @"WKS", //       = 11,     /* Well known service. */
    @"PTR", //       = 12,     /* Domain name pointer. */
    @"HINFO", //     = 13,     /* Host information. */
    @"MINFO", //     = 14,     /* Mailbox information. */
    @"MX", //        = 15,     /* Mail routing information. */
    @"TXT" //       = 16,     /* One or more text strings (NOT "zero or more..."). */
    // this isn't a complete list; it just includes the most common ones.
    // For the full list, see the "kDNSServiceType_..." constants in <dns_sd.h>.
};

@interface MYBonjourQuery ()
@property (copy) NSData *recordData;
@end


@implementation MYBonjourQuery


- (id) initWithBonjourService: (MYBonjourService*)service recordType: (uint16_t)recordType;
{
    self = [super init];
    if (self) {
        _bonjourService = service;
        _recordType = recordType;
    }
    return self;
}

- (void) dealloc
{
    [_recordData release];
    [super dealloc];
}


- (NSString*) description
{
    NSString *typeName;
    if (_recordType <= 16)
        typeName = kRecordTypeNames[_recordType];
    else
        typeName = $sprintf(@"%u", _recordType);
    return $sprintf(@"%@[%@ /%@]", self.class, _bonjourService.name, typeName);
}


@synthesize recordData=_recordData;


- (void) priv_gotRecordBytes: (const void *)rdata
                      length: (uint16_t)rdlen
                        type: (uint16_t)rrtype
                         ttl: (uint32_t)ttl
                       flags: (DNSServiceFlags)flags
{
    NSData *data = [NSData dataWithBytes: rdata length: rdlen];
    if (!$equal(data,_recordData)) {
        if (data.length <= 16)
            LogTo(Bonjour,@"%@ = %@", self, data);
        else
            LogTo(Bonjour,@"%@ = %@...", self, [data subdataWithRange: NSMakeRange(0,16)]);
        self.recordData = data;
    }
    [_bonjourService queryDidUpdate: self];
}


static void queryCallback( DNSServiceRef                       DNSServiceRef,
                           DNSServiceFlags                     flags,
                           uint32_t                            interfaceIndex,
                           DNSServiceErrorType                 errorCode,
                           const char                          *fullname,
                           uint16_t                            rrtype,
                           uint16_t                            rrclass,
                           uint16_t                            rdlen,
                           const void                          *rdata,
                           uint32_t                            ttl,
                           void                                *context)
{
    MYBonjourQuery *query = context;
    [query retain];
    @try{
        //LogTo(Bonjour, @"queryCallback for %@ (err=%i)", context,errorCode);
        if (!errorCode)
            [query priv_gotRecordBytes: rdata
                                length: rdlen
                                  type: rrtype
                                   ttl: ttl
                                 flags: flags];
    }catchAndReport(@"MYBonjourResolver query callback");
    [query gotResponse: errorCode];
    [query release];
}


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    const char *fullName = _bonjourService.fullName.UTF8String;
    if (fullName)
        return DNSServiceQueryRecord(sdRefPtr,
                                     kDNSServiceFlagsShareConnection, 
                                     _bonjourService.interfaceIndex, 
                                     fullName,
                                     _recordType, kDNSServiceClass_IN, 
                                     &queryCallback, self);
    else
        return kDNSServiceErr_NoSuchName;
}


@end


/*
 Copyright (c) 2009, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
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
