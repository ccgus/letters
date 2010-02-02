//
//  IntegerArray.m
//  Cloudy
//
//  Created by Jens Alfke on 6/23/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "IntegerArray.h"


@implementation IntegerArray

- (id) init
{
    self = [super init];
    if (self != nil) {
        _storage = [[NSMutableData alloc] initWithCapacity: 10*sizeof(SInt32)];
    }
    return self;
}

- (void) dealloc
{
    [_storage release];
    [super dealloc];
}



- (NSUInteger)count             {return _count;}
- (const SInt32*) allIntegers   {return _integers;}

- (SInt32) integerAtIndex: (NSUInteger)index
{
    Assert(index<_count);
    return _integers[index];
}

- (void) setInteger: (SInt32)value atIndex: (NSUInteger)index
{
    Assert(index<_count);
    _integers[index] = value;
}

- (void) addInteger: (SInt32)value
{
    [_storage appendBytes: &value length: sizeof(value)];
    _count++;
    _integers = [_storage mutableBytes];
}

@end
