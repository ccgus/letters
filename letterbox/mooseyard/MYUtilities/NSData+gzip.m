//
//  NSData+gzip.m
//  Cloudy
//
//  Created by Jens Alfke on 6/27/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "NSData+gzip.h"
#import "GTMNSData+zlib.h"

@implementation NSData (gzip)

- (NSData*) my_gzippedWithCompression: (int)compression {
    return [NSData gtm_dataByGzippingBytes: self.bytes
                                    length: self.length
                          compressionLevel: compression];
}

- (NSData*) my_gunzipped {
    return [NSData gtm_dataByInflatingBytes: self.bytes length: self.length];
}

@end
