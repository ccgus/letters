//
//  ValueArray.m
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "ValueArray.h"


@implementation ValueArray


- (id) initWithCount: (unsigned)count valueSize: (size_t)valueSize
{
    self = [super init];
    if( self ) {
        _count = count;
        _valueSize = valueSize;
    }
    return self;
}

+ (ValueArray*) valueArrayWithCount: (unsigned)count valueSize: (size_t)valueSize
{
    return [[(ValueArray*)NSAllocateObject(self,count*valueSize,nil)
                            initWithCount: count valueSize: valueSize] 
                                autorelease];
}

- (unsigned) count      {return _count;}
- (size_t) valueSize    {return _valueSize;}

- (const void*) valueAtIndex: (unsigned)i
{
    NSParameterAssert(i<_count);
    return (const char*)object_getIndexedIvars(self) + i*_valueSize;
}

- (void) getValue: (void*)value atIndex: (unsigned)i
{
    NSParameterAssert(i<_count);
    NSParameterAssert(value!=NULL);
    memcpy(value, object_getIndexedIvars(self) + i*_valueSize, _valueSize);
}

- (void) setValue: (const void*)value atIndex: (unsigned)i
{
    NSParameterAssert(i<_count);
    NSParameterAssert(value!=NULL);
    memcpy(object_getIndexedIvars(self) + i*_valueSize, value, _valueSize);
}



- (id)initWithCoder:(NSCoder *)decoder
{
    NSParameterAssert([decoder allowsKeyedCoding]);
    NSKeyedUnarchiver *arch = (NSKeyedUnarchiver*)decoder;
    unsigned count = [arch decodeIntForKey: @"count"];
    size_t valueSize = [arch decodeIntForKey: @"valueSize"];
    
    [super release];
    self = [[[self class] valueArrayWithCount: count valueSize: valueSize] retain];
    if( self ) {
        unsigned nBytes;
        const void *bytes = [arch decodeBytesForKey: @"values" returnedLength: &nBytes];
        NSAssert(nBytes==count*valueSize,@"Value size mismatch");
        memcpy( object_getIndexedIvars(self), bytes, nBytes );
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    NSParameterAssert([coder allowsKeyedCoding]);
    NSKeyedArchiver *arch = (NSKeyedArchiver*)coder;
    
    [arch encodeInt: _count forKey: @"count"];
    [arch encodeInt: _valueSize forKey: @"valueSize"];
    [arch encodeBytes: object_getIndexedIvars(self)
               length: _count*_valueSize
               forKey: @"values"];
}    


@end


ImplementValueArrayOf(Int,int)

ImplementValueArrayOf(Double,double)


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
