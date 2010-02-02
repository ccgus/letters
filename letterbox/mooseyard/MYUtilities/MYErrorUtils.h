//
//  MYErrorUtils.h
//  MYCrypto
//
//  Created by Jens Alfke on 2/25/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import <Foundation/NSObject.h>
@class NSError, NSString;


extern NSString* const MYErrorDomain;

enum {
    /** "Miscellaneous" error code, set by MYMiscError.
        Handy during development, but before shipping you really should define
        individual error codes for each error condition. */
    kMYErrorMisc = 999999,
};


/** Creates an NSError in MYErrorDomain. */
NSError *MYError( int errorCode, NSString *domain, NSString *messageFormat, ... ) 
                                __attribute__ ((format (__NSString__, 3, 4)));

/** A variant of MYError, useful for returning from a method.
    If errorCode is nonzero, constructs an NSError and stores it into *outError,
    then returns NO. Otherwise returns YES. */
BOOL MYReturnError( NSError **outError,
                    int errorCode, NSString *domain, NSString *messageFormat, ... ) 
                                __attribute__ ((format (__NSString__, 4, 5)));

/** Convenience function for creating NSErrors.
    Stores an NSError into *error, and returns NO.
    Domain will be MYErrorDomain, code will be kMYErrorMisc.
    Handy during development, but before shipping you really should define
    individual error codes for each error condition. */
BOOL MYMiscError( NSError **outError, NSString *messageFormat, ... )
                                __attribute__ ((format (__NSString__, 2, 3)));

NSString* MYPrintableErrorCode( int code );
NSString* MYErrorName( NSString *domain, int code );

@interface NSError (MYUtilities)
/** Prepends a message to the beginning of the receiver's existing message,
    and returns the modified NSError. */
- (NSError*) my_errorByPrependingMessage: (NSString*)message;

- (NSString*) my_nameOfCode;

@end
