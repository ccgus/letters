//
//  IntegerArray.h
//  Cloudy
//
//  Created by Jens Alfke on 6/23/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IntegerArray : NSObject {
    NSMutableData *_storage;
    SInt32 *_integers;
    NSUInteger _count;
}

- (NSUInteger)count;
- (const SInt32*) allIntegers;

- (SInt32) integerAtIndex: (NSUInteger)index;
- (void) setInteger: (SInt32)value atIndex: (NSUInteger)index;
- (void) addInteger: (SInt32)value;

@end
