//
//  KVUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 2/25/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum {
    MYKeyValueObservingOptionOnce = 1<<31,
    MYKeyValueObservingOptionDelayed = 1<<30
};



@interface Observance : NSObject
{
    id _target;
    id _observed;
    NSString *_keyPath;
    NSKeyValueObservingOptions _options;
    SEL _action;
}

- (id) initWithTarget: (id)target 
               action: (SEL)action
             observed: (id)observed
              keyPath: (NSString*)keyPath 
              options: (NSKeyValueObservingOptions)options;

- (void) stopObserving;

@property (readonly) id observed;
@property (readonly) NSString* keyPath;

@end



@interface Observer : NSObject
{
    id _target;
    NSMutableArray *_observances;
}

- (id) initWithTarget: (id)target;

@property (readonly) id target;

- (void) observe: (id)observed 
         keyPath: (NSString*)keyPath 
         options: (NSKeyValueObservingOptions)options
          action: (SEL)action;

- (void) observe: (id)observed 
         keyPath: (NSString*)keyPath 
          action: (SEL)action;

/** observed or keyPath may be nil, meaning wildcard */
- (void) stopObserving: (id)observedOrNil keyPath: (NSString*)keyPathOrNil;
- (void) stopObserving: (id)observed;
- (void) stopObserving;

@end
