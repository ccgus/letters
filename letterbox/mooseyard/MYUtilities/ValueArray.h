//
//  ValueArray.h
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ValueArray : NSObject <NSCoding>
{
    unsigned _count;
    size_t _valueSize;
}

+ (ValueArray*) valueArrayWithCount: (unsigned)count valueSize: (size_t)valueSize;

- (unsigned) count;
- (size_t) valueSize;
- (const void*) valueAtIndex: (unsigned)i;
- (void) getValue: (void*)value atIndex: (unsigned)i;
- (void) setValue: (const void*)value atIndex: (unsigned)i;

@end


#define DeclareValueArrayOf(CAPTYPE,TYPE) \
            @interface CAPTYPE##Array : ValueArray \
            + (CAPTYPE##Array*) TYPE##ArrayWithCount: (unsigned)count; \
            - (TYPE) TYPE##AtIndex: (unsigned)index; \
            - (void) set##CAPTYPE: (TYPE)value atIndex: (unsigned)index; \
            @end

#define ImplementValueArrayOf(CAPTYPE,TYPE) \
            @implementation CAPTYPE##Array \
            + (CAPTYPE##Array*) TYPE##Array##WithCount: (unsigned)count \
                {return (id)[super valueArrayWithCount: count valueSize: sizeof(TYPE)];} \
            - (TYPE) TYPE##AtIndex: (unsigned)i; \
                {NSParameterAssert(i<_count); return ((const TYPE*)object_getIndexedIvars(self))[i];}\
            - (void) set##CAPTYPE: (TYPE)value atIndex: (unsigned)i \
                {NSParameterAssert(i<_count); ((TYPE*)object_getIndexedIvars(self))[i] = value;}\
            @end


// Declares IntArray class
DeclareValueArrayOf(Int,int)

DeclareValueArrayOf(Double,double)
