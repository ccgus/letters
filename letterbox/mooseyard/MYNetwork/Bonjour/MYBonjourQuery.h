//
//  MYBonjourQuery.h
//  MYNetwork
//
//  Created by Jens Alfke on 4/24/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYDNSService.h"
@class MYBonjourService;


/** A query for a particular DNS record (TXT, NULL, etc.) of a Bonjour service.
    This class is used internally by MYBonjourService to track the TXT record;
    you won't need to use it directly, unless you're interested in the contents of some other
    record (such as the NULL record that iChat's _presence._tcp service uses for buddy icons.) */
@interface MYBonjourQuery : MYDNSService 
{
    @private
    MYBonjourService *_bonjourService;
    uint16_t _recordType;
    NSData *_recordData;
}

/** Initializes a query for a particular service and record type.
    @param service  The Bonjour service to query
    @param recordType  The DNS record type, e.g. kDNSServiceType_TXT; see the enum in <dns_sd.h>. */
- (id) initWithBonjourService: (MYBonjourService*)service 
                   recordType: (uint16_t)recordType;

/** The data of the DNS record, once it's been found.
    This property is KV-observable. */
@property (readonly,copy) NSData *recordData;

@end
