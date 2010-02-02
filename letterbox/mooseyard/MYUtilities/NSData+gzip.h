//
//  NSData+gzip.h
//  Cloudy
//
//  Created by Jens Alfke on 6/27/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSData (GZip)

- (NSData*) my_gzippedWithCompression: (int)compression;
- (NSData*) my_gunzipped;

@end
