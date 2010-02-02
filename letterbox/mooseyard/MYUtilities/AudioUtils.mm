//
//  AudioUtils.mm
//  Cloudy
//
//  Created by Jens Alfke on 6/17/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "AudioUtils.h"


NSString* MYCAErrorString( OSStatus coreAudioError )
{
    if( coreAudioError >= 0x20202020 )
        return NSFileTypeForHFSTypeCode(coreAudioError);
    else
        return [NSString stringWithFormat: @"%i",coreAudioError];
}

NSError* MYCAError( OSStatus coreAudioError, NSString *message )
{
    NSString *errStr = $sprintf(@"CoreAudio error %@", MYCAErrorString(coreAudioError));
    if( message )
        message = [message stringByAppendingFormat: @" [%@]", errStr];
    else
        message = errStr;
    NSString *domain = (coreAudioError >= 0x20202020) ?MYCoreAudioErrorDomain :NSOSStatusErrorDomain;
    return [NSError errorWithDomain: domain code: coreAudioError
                           userInfo: $dict({NSLocalizedDescriptionKey, message})];
}


void _MYThrowCAError( OSStatus err, NSString *operation ) throw(NSError*)
{
    NSError *error = MYCAError(err, $sprintf(@"Error in %@", operation));
    Warn(@"EXCEPTION: %@",error.localizedDescription);
    throw error;
}

void _MYWarnCAError( OSStatus err, NSString *operation )
{
    NSError *error = MYCAError(err, $sprintf(@"Error in %@", operation));
    Warn(@"%@",error.localizedDescription);
}
