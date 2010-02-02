//
//  MYBonjourBrowser.m
//  MYNetwork
//
//  Created by Jens Alfke on 1/22/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYBonjourBrowser.h"
#import "MYBonjourService.h"
#import "MYBonjourRegistration.h"
#import "ExceptionUtils.h"
#import "Test.h"
#import "Logging.h"
#import <dns_sd.h>


static void browseCallback (DNSServiceRef                       sdRef,
                            DNSServiceFlags                     flags,
                            uint32_t                            interfaceIndex,
                            DNSServiceErrorType                 errorCode,
                            const char                          *serviceName,
                            const char                          *regtype,
                            const char                          *replyDomain,
                            void                                *context);

@interface MYBonjourBrowser ()
@property BOOL browsing;
- (void) _updateServiceList;
@end


@implementation MYBonjourBrowser


- (id) initWithServiceType: (NSString*)serviceType
{
    Assert(serviceType);
    self = [super init];
    if (self != nil) {
        self.continuous = YES;
        _serviceType = [serviceType copy];
        _services = [[NSMutableSet alloc] init];
        _addServices = [[NSMutableSet alloc] init];
        _rmvServices = [[NSMutableSet alloc] init];
        _serviceClass = [MYBonjourService class];
    }
    return self;
}


- (void) dealloc
{
    LogTo(Bonjour,@"DEALLOC MYBonjourBrowser");
    [_myRegistration cancel];
    [_myRegistration release];
    [_serviceType release];
    [_services release];
    [_addServices release];
    [_rmvServices release];
    [super dealloc];
}


@synthesize delegate=_delegate, browsing=_browsing, services=_services, serviceClass=_serviceClass;


- (NSString*) description
{
    return $sprintf(@"%@[%@]", self.class,_serviceType);
}


- (DNSServiceErrorType) createServiceRef: (DNSServiceRef*)sdRefPtr {
    return DNSServiceBrowse(sdRefPtr,
                            kDNSServiceFlagsShareConnection, 
                            0,
                            _serviceType.UTF8String, NULL,
                            &browseCallback, self);
}


- (void) priv_gotError: (DNSServiceErrorType)errorCode {
    LogTo(Bonjour,@"%@ got error %i", self,errorCode);
    self.error = errorCode;
}

- (void) priv_gotServiceName: (NSString*)serviceName
                        type: (NSString*)regtype
                      domain: (NSString*)domain
                   interface: (uint32_t)interfaceIndex
                       flags: (DNSServiceFlags)flags
{
    // Create (or reuse existing) MYBonjourService object:
    MYBonjourService *service = [[_serviceClass alloc] initWithBrowser: self
                                                                  name: serviceName
                                                                  type: regtype
                                                                domain: domain
                                                             interface: interfaceIndex];
    if ([_myRegistration isSameAsService: service]) {
        // This is an echo of my own registration, so ignore it
        LogTo(Bonjour,@"%@ ignoring echo %@", self,service);
        [service release];
        return;
    }
    MYBonjourService *existingService = [_services member: service];
    if( existingService ) {
        // Use existing service object instead of creating a new one
        [service release];
        service = [existingService retain];
    }
    
    // Add it to the add/remove sets:
    NSMutableSet *addTo, *removeFrom;
    if (flags & kDNSServiceFlagsAdd) {
        addTo = _addServices;
        removeFrom = _rmvServices;
    } else {
        addTo = _rmvServices;
        removeFrom = _addServices;
    }
    if( [removeFrom containsObject: service] )
        [removeFrom removeObject: service];
    else
        [addTo addObject: service];
    [service release];
    
    // Schedule a (single) call to _updateServiceList:
    if (!_pendingUpdate) {
        [self performSelector: @selector(_updateServiceList) withObject: nil afterDelay: 0];
        _pendingUpdate = YES;
    }
}


- (void) _updateServiceList
{
    _pendingUpdate = NO;
    if( _rmvServices.count ) {
        [self willChangeValueForKey: @"services" 
                    withSetMutation: NSKeyValueMinusSetMutation
                       usingObjects: _rmvServices];
        [_services minusSet: _rmvServices];
        [self didChangeValueForKey: @"services" 
                   withSetMutation: NSKeyValueMinusSetMutation
                      usingObjects: _rmvServices];
        [_rmvServices makeObjectsPerformSelector: @selector(removed)];
        [_rmvServices removeAllObjects];
    }
    if( _addServices.count ) {
        [_addServices makeObjectsPerformSelector: @selector(added)];
        [self willChangeValueForKey: @"services" 
                    withSetMutation: NSKeyValueUnionSetMutation
                       usingObjects: _addServices];
        [_services unionSet: _addServices];
        [self didChangeValueForKey: @"services" 
                   withSetMutation: NSKeyValueUnionSetMutation
                      usingObjects: _addServices];
        [_addServices removeAllObjects];
    }
}


static void browseCallback (DNSServiceRef        sdRef,
                            DNSServiceFlags      flags,
                            uint32_t             interfaceIndex,
                            DNSServiceErrorType  errorCode,
                            const char           *serviceName,
                            const char           *regtype,
                            const char           *replyDomain,
                            void                 *context)
{
    MYBonjourBrowser *browser = context;
    @try{
        LogTo(Bonjour,@"browseCallback (error=%i, name='%s', intf=%u)", errorCode,serviceName,interfaceIndex);
        if (!errorCode)
            [browser priv_gotServiceName: [NSString stringWithUTF8String: serviceName]
                                    type: [NSString stringWithUTF8String: regtype]
                                  domain: [NSString stringWithUTF8String: replyDomain]
                               interface: interfaceIndex
                                   flags: flags];
    }catchAndReport(@"Bonjour");
    [browser gotResponse: errorCode];
}


- (void) cancel {
    [_myRegistration stop];
    [super cancel];
}


- (MYBonjourRegistration *) myRegistration {
    if (!_myRegistration)
        _myRegistration = [[MYBonjourRegistration alloc] initWithServiceType: _serviceType port: 0];
    return _myRegistration;
}


@end




#pragma mark -
#pragma mark TESTING:

#if DEBUG

#import "MYBonjourQuery.h"
#import "MYAddressLookup.h"

@interface BonjourTester : NSObject
{
    MYBonjourBrowser *_browser;
}
@end

@implementation BonjourTester

- (id) init
{
    self = [super init];
    if (self != nil) {
        _browser = [[MYBonjourBrowser alloc] initWithServiceType: @"_presence._tcp"];
        [_browser addObserver: self forKeyPath: @"services" 
                      options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew 
                      context: NULL];
        [_browser addObserver: self forKeyPath: @"browsing" 
                      options: NSKeyValueObservingOptionNew
                      context: NULL];
        [_browser start];
        
        MYBonjourRegistration *myReg = _browser.myRegistration;
        myReg.port = 12346;
        Assert([myReg start]);
    }
    return self;
}

- (void) dealloc
{
    [_browser stop];
    [_browser removeObserver: self forKeyPath: @"services"];
    [_browser removeObserver: self forKeyPath: @"browsing"];
    [_browser release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    Log(@"Observed change in %@: %@",keyPath,change);
    if( $equal(keyPath,@"services") ) {
        if( [[change objectForKey: NSKeyValueChangeKindKey] intValue]==NSKeyValueChangeInsertion ) {
            NSSet *newServices = [change objectForKey: NSKeyValueChangeNewKey];
            for( MYBonjourService *service in newServices ) {
                Log(@"##### %@ : at %@:%hu, TXT=%@", 
                      service, service.hostname, service.port, service.txtRecord);
                service.addressLookup.continuous = YES;
                [service.addressLookup addObserver: self
                                        forKeyPath: @"addresses"
                                           options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                                           context: NULL];
                [service queryForRecord: kDNSServiceType_NULL];
            }
        } else if( [[change objectForKey: NSKeyValueChangeKindKey] intValue]==NSKeyValueChangeRemoval ) {
            NSSet *oldServices = [change objectForKey: NSKeyValueChangeOldKey];
            for( MYBonjourService *service in oldServices ) {
                Log(@"##### REMOVED: %@", service);
                [service.addressLookup removeObserver: self forKeyPath: @"addresses"];
            }
        }
    }
}

@end

TestCase(Bonjour) {
    EnableLogTo(Bonjour,YES);
    EnableLogTo(DNS,YES);
    [NSRunLoop currentRunLoop]; // create runloop
    BonjourTester *tester = [[BonjourTester alloc] init];
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1500]];
    [tester release];
}

#endif


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
