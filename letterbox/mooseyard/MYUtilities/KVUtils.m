//
//  KVUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 2/25/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "KVUtils.h"


@implementation Observance

- (id) initWithTarget: (id)target 
               action: (SEL)action
             observed: (id)observed
              keyPath: (NSString*)keyPath 
              options: (NSKeyValueObservingOptions)options
{
    self = [super init];
    if (self != nil) {
        _target = target;
        _action = action;
        _observed = observed;
        _keyPath = [keyPath copy];
        _options = options;
        
        options &= ~(MYKeyValueObservingOptionOnce | MYKeyValueObservingOptionDelayed);
        
        [_observed addObserver: self forKeyPath: _keyPath options: options context: _action];
    }
    return self;
}

- (void) dealloc
{
    [_observed removeObserver: self forKeyPath: _keyPath];
    [_keyPath release];
    [super dealloc];
}


@synthesize observed=_observed, keyPath=_keyPath;


- (void) stopObserving
{
    [_observed removeObserver: self forKeyPath: _keyPath];
    _observed = nil;
    _target = nil;
    _action = NULL;
}


- (void) _callTargetWithChange: (NSDictionary*)change
{
    @try{
        [_target performSelector: _action withObject: _observed withObject: change];
    }@catch( NSException *x ) {
        Warn(@"Uncaught exception in -[%@<%p> %s] while observing change of key-path %@ in %@<%p>: %@",
             _target,_target, _action, _keyPath, _observed,_observed, x);
        [NSApp reportException: x];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
    if( object == _observed ) {
        if( _options & MYKeyValueObservingOptionDelayed )
            [self performSelector: @selector(_callTargetWithChange:) withObject: change
                       afterDelay: 0.0];
        else
            [self _callTargetWithChange: change];
        if( _options & MYKeyValueObservingOptionOnce )
            [self stopObserving];
    }
}


@end




@implementation Observer


- (id) init
{
    return [self initWithTarget: self];
}



- (id) initWithTarget: (id)target
{
    Assert(target);
    self = [super init];
    if (self != nil) {
        _target = target;
        _observances = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) dealloc
{
    [self stopObserving];
    [_observances release];
    [super dealloc];
}


@synthesize target=_target;


- (void) observe: (id)observed 
         keyPath: (NSString*)keyPath 
         options: (NSKeyValueObservingOptions)options
          action: (SEL)action
{
    Observance *o = [[Observance alloc] initWithTarget: _target
                                                action: action
                                              observed: observed
                                               keyPath: keyPath
                                               options: options];
    [_observances addObject: o];
    [o release];
}


- (void) observe: (id)observed 
         keyPath: (NSString*)keyPath 
          action: (SEL)action
{
    [self observe: observed keyPath: keyPath options: 0 action: action];
}


- (void) stopObserving
{
    [_observances makeObjectsPerformSelector: @selector(stopObserving)];
    [_observances removeAllObjects];
}


- (void) stopObserving: (id)observed
{
    [self stopObserving: observed keyPath: nil];
}


- (void) stopObserving: (id)observed keyPath: (NSString*)keyPath
{
    // observed or keyPath may be nil
    for( int i=_observances.count-1; i>=0; i-- ) {
        Observance *o = [_observances objectAtIndex: i];
        if( (observed==nil || observed==o.observed) && (keyPath==nil || [keyPath isEqual: o.keyPath]) ) {
            [o stopObserving];
            [_observances removeObjectAtIndex: i];
        }
    }
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
