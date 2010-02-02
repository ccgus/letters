//
//  AudioUtils.h
//  Cloudy
//
//  Created by Jens Alfke on 6/17/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    #define MYCoreAudioErrorDomain @"MYCoreAudioDomain"

    NSString* MYCAErrorString( OSStatus coreAudioError );
    NSError* MYCAError( OSStatus coreAudioError, NSString *message );

#ifdef __cplusplus
}
#endif

       

#define XWarnIfError(error, operation) \
    do {																	\
        OSStatus __err = error;												\
        if (__err) _MYWarnCAError(__err,@""operation);	\
    } while (0)

void _MYWarnCAError( OSStatus error, NSString *operation );

#ifdef __cplusplus

    #define XThrowIfError(error, operation) \
        do {																	\
            OSStatus __err = error;												\
            if (__err) _MYThrowCAError(__err,@""operation);	\
        } while (0)

    void _MYThrowCAError( OSStatus error, NSString *operation ) throw(NSError*) __attribute__((noreturn));

#endif __cplusplus
