//
//  URLUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 4/28/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (MYUtilities)

/** Smart/lenient version of +URLWithString:, for use with user-entered URLs.
    - Strips out any whitespace or newlines
    - Removes surrounding "<...>"
    - Adds a default scheme like http: if necessary, if one is provided
    - Checks against a list of allowed schemes, if one is provided */
+ (NSURL*) my_URLWithLenientString: (NSString*)string 
                     defaultScheme: (NSString*)defaultScheme
                    allowedSchemes: (NSArray*)allowedSchemes;
@end


@interface NSHTTPURLResponse (MYUtilities)

- (NSError*) HTTPError;

@end

extern NSString* const MyHTTPErrorDomain;
