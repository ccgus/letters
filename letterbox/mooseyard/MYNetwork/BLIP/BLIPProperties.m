//
//  BLIPProperties.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/13/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPProperties.h"
#import "Logging.h"
#import "Test.h"


/** Common strings are abbreviated as single-byte strings in the packed form.
    The ascii value of the single character minus one is the index into this table. */
static const char* kAbbreviations[] = {
    "Content-Type",
    "Profile",
    "application/octet-stream",
    "text/plain; charset=UTF-8",
    "text/xml",
    "text/yaml",
    "Channel",
    "Error-Code",
    "Error-Domain",
};
#define kNAbbreviations ((sizeof(kAbbreviations)/sizeof(const char*)))  // cannot exceed 31!



@interface BLIPPackedProperties : BLIPProperties
{
    NSData *_data;
    int _count;
    const char **_strings;
    int _nStrings;
}

@end



// The base class just represents an immutable empty collection.
@implementation BLIPProperties


+ (BLIPProperties*) propertiesWithEncodedData: (NSData*)data usedLength: (ssize_t*)usedLength
{
    size_t available = data.length;
    if( available < sizeof(UInt16) ) {
        // Not enough available to read length:
        *usedLength = 0;
        return nil;
    }
    
    // Read the length:
    const char *bytes = data.bytes;
    size_t length = NSSwapBigShortToHost( *(UInt16*)bytes ) + sizeof(UInt16);
    if( length > available ) {
        // Properties not complete yet.
        *usedLength = 0;
        return nil;
    }
    
    // Complete -- try to create an object:
    BLIPProperties *props;
    if( length > sizeof(UInt16) )
        props = [[[BLIPPackedProperties alloc] initWithBytes: bytes length: length] autorelease];
    else
        props = [BLIPProperties properties];
    
    *usedLength = props ?(ssize_t)length :-1;
    return props;
}


- (id) copyWithZone: (NSZone*)zone
{
    return [self retain];
}

- (id) mutableCopyWithZone: (NSZone*)zone
{
    return [[BLIPMutableProperties allocWithZone: zone] initWithDictionary: self.allProperties];
}

- (BOOL) isEqual: (id)other
{
    return [other isKindOfClass: [BLIPProperties class]]
        && [self.allProperties isEqual: [other allProperties]];
}

- (NSString*) valueOfProperty: (NSString*)prop  {return nil;}
- (NSDictionary*) allProperties                 {return [NSDictionary dictionary];}
- (NSUInteger) count                            {return 0;}
- (NSUInteger) dataLength                       {return sizeof(UInt16);}

- (NSData*) encodedData
{
    UInt16 len = 0;
    return [NSData dataWithBytes: &len length: sizeof(len)];
}


+ (BLIPProperties*) properties
{
    static BLIPProperties *sEmptyInstance;
    if( ! sEmptyInstance )
        sEmptyInstance = [[self alloc] init];
    return sEmptyInstance;
}


@end



/** Internal immutable subclass that keeps its contents in the packed data representation. */
@implementation BLIPPackedProperties


- (id) initWithBytes: (const char*)bytes length: (size_t)length
{
    self = [super init];
    if (self != nil) {
        // Copy data, then skip the length field:
        _data = [[NSData alloc] initWithBytes: bytes length: length];
        bytes = (const char*)_data.bytes + sizeof(UInt16);
        length -= sizeof(UInt16);
        
        if( bytes[length-1]!='\0' )
            goto fail;

        // The data consists of consecutive NUL-terminated strings, alternating key/value:
        int capacity = 0;
        const char *end = bytes+length;
        for( const char *str=bytes; str < end; str += strlen(str)+1, _nStrings++ ) {
            if( _nStrings >= capacity ) {
                capacity = capacity ?(2*capacity) :4;
                _strings = realloc(_strings, capacity*sizeof(const char**));
            }
            UInt8 first = (UInt8)str[0];
            if( first>'\0' && first<' ' && str[1]=='\0' ) {
                // Single-control-character property string is an abbreviation:
                if( first > kNAbbreviations )
                    goto fail;
                _strings[_nStrings] = kAbbreviations[first-1];
            } else
                _strings[_nStrings] = str;
        }
        
        // It's illegal for the data to end with a non-NUL or for there to be an odd number of strings:
        if( (_nStrings & 1) )
            goto fail;
        
        return self;
            
    fail:
        Warn(@"BLIPProperties: invalid data");
        [self release];
        return nil;
    }
    return self;
}


- (void) dealloc
{
    if( _strings ) free(_strings);
    [_data release];
    [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
    return [self retain];
}

- (id) mutableCopyWithZone: (NSZone*)zone
{
    return [[BLIPMutableProperties allocWithZone: zone] initWithDictionary: self.allProperties];
}


- (NSString*) valueOfProperty: (NSString*)prop
{
    const char *propStr = [prop UTF8String];
    Assert(propStr);
    // Search in reverse order so that later values will take precedence over earlier ones.
    for( int i=_nStrings-2; i>=0; i-=2 ) {
        if( strcmp(propStr, _strings[i]) == 0 )
            return [NSString stringWithUTF8String: _strings[i+1]];
    }
    return nil;
}


- (NSDictionary*) allProperties
{
    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithCapacity: _nStrings/2];
    // Add values in forward order so that later ones will overwrite (take precedence over)
    // earlier ones, which matches the behavior of -valueOfProperty.
    // (However, note that unlike -valueOfProperty, this dictionary is case-sensitive!)
    for( int i=0; i<_nStrings; i+=2 ) {
        NSString *key = [[NSString alloc] initWithUTF8String: _strings[i]];
        NSString *value = [[NSString alloc] initWithUTF8String: _strings[i+1]];
        if( key && value )
            [props setObject: value forKey: key];
        [key release];
        [value release];
    }
    return props;
}


- (NSUInteger) count        {return _nStrings/2;}
- (NSData*) encodedData            {return _data;}
- (NSUInteger) dataLength   {return _data.length;}


@end



/** Mutable subclass that stores its properties in an NSMutableDictionary. */
@implementation BLIPMutableProperties


+ (BLIPProperties*) properties
{
    return [[[self alloc] initWithDictionary: nil] autorelease];
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        _properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) initWithDictionary: (NSDictionary*)dict
{
    self = [super init];
    if (self != nil) {
        _properties = dict ?[dict mutableCopy] :[[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) initWithProperties: (BLIPProperties*)properties
{
    return [self initWithDictionary: [properties allProperties]];
}

- (void) dealloc
{
    [_properties release];
    [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
    ssize_t usedLength;
    BLIPProperties *copy = [BLIPProperties propertiesWithEncodedData: self.encodedData usedLength: &usedLength];
    Assert(copy);
    return [copy retain];
}


- (NSString*) valueOfProperty: (NSString*)prop
{
    return [_properties objectForKey: prop];
}

- (NSDictionary*) allProperties
{
    return _properties;
}

- (NSUInteger) count        {return _properties.count;}


static void appendStr( NSMutableData *data, NSString *str ) {
    const char *utf8 = [str UTF8String];
    size_t size = strlen(utf8)+1;
    for( unsigned i=0; i<kNAbbreviations; i++ )
        if( memcmp(utf8,kAbbreviations[i],size)==0 ) {
            const UInt8 abbrev[2] = {i+1,0};
            [data appendBytes: &abbrev length: 2];
            return;
        }
    [data appendBytes: utf8 length: size];
}

- (NSData*) encodedData
{
    NSMutableData *data = [NSMutableData dataWithCapacity: 16*_properties.count];
    [data setLength: sizeof(UInt16)]; // leave room for length
    for( NSString *name in _properties ) {
        appendStr(data,name);
        appendStr(data,[_properties objectForKey: name]);
    }
    
    NSUInteger length = data.length - sizeof(UInt16);
    if( length > 0xFFFF )
        return nil;
    *(UInt16*)[data mutableBytes] = NSSwapHostShortToBig((UInt16)length);
    return data;
}

    
- (void) setValue: (NSString*)value ofProperty: (NSString*)prop
{
    Assert(prop.length>0);
    if( value )
        [_properties setObject: value forKey: prop];
    else
        [_properties removeObjectForKey: prop];
}


- (void) setAllProperties: (NSDictionary*)properties
{
    if( properties.count ) {
        for( id key in properties ) {
            Assert([key isKindOfClass: [NSString class]]);
            Assert([key length] > 0);
            Assert([[properties objectForKey: key] isKindOfClass: [NSString class]]);
        }
        [_properties setDictionary: properties];
    } else
        [_properties removeAllObjects];
}


@end




TestCase(BLIPProperties) {
    BLIPProperties *props;
    
    props = [BLIPProperties properties];
    CAssert(props);
    CAssertEq(props.count,0U);
    Log(@"Empty properties:\n%@", props.allProperties);
    NSData *data = props.encodedData;
    Log(@"As data: %@", data);
    CAssertEqual(data,[NSMutableData dataWithLength: 2]);
    
    BLIPMutableProperties *mprops = [props mutableCopy];
    Log(@"Mutable copy:\n%@", mprops.allProperties);
    data = mprops.encodedData;
    Log(@"As data: %@", data);
    CAssertEqual(data,[NSMutableData dataWithLength: 2]);
    
    ssize_t used;
    props = [BLIPProperties propertiesWithEncodedData: data usedLength: &used];
    CAssertEq(used,(ssize_t)data.length);
    CAssertEqual(props,mprops);
    
    [mprops setValue: @"Jens" ofProperty: @"First-Name"];
    [mprops setValue: @"Alfke" ofProperty: @"Last-Name"];
    [mprops setValue: @"" ofProperty: @"Empty-String"];
    [mprops setValue: @"Z" ofProperty: @"A"];
    Log(@"With properties:\n%@", mprops.allProperties);
    data = mprops.encodedData;
    Log(@"As data: %@", data);
    
    for( unsigned len=0; len<data.length; len++ ) {
        props = [BLIPProperties propertiesWithEncodedData: [data subdataWithRange: NSMakeRange(0,len)]
                                                                usedLength: &used];
        CAssertEq(props,nil);
        CAssertEq(used,0);
    }
    props = [BLIPProperties propertiesWithEncodedData: data usedLength: &used];
    CAssertEq(used,(ssize_t)data.length);
    Log(@"Read back in:\n%@",props.allProperties);
    CAssertEqual(props,mprops);
    
    NSDictionary *all = mprops.allProperties;
    for( NSString *prop in all )
        CAssertEqual([props valueOfProperty: prop],[all objectForKey: prop]);
	
	[mprops release];
}


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
