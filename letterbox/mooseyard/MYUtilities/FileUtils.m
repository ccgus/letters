//
//  FileUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 1/14/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "FileUtils.h"


OSStatus PathToFSRef( NSString *path, FSRef *fsRef )
{
    NSCParameterAssert(path);
    return FSPathMakeRef((const UInt8 *)[path UTF8String],fsRef,NULL);
}

OSStatus FSRefToPath( const FSRef *fsRef, NSString **outPath )
{
    NSURL *url = (id) CFURLCreateFromFSRef(NULL,fsRef);
    if( ! url )
        return paramErr;
    *outPath = [url path];
    [url release];
    return noErr;
}


BOOL CheckOSErr( OSStatus err, NSError **error )
{
    if( err ) {
        if( error )
            *error = [NSError errorWithDomain: NSOSStatusErrorDomain code: err userInfo: nil];
        return NO;
    } else {
        return YES;
    }
}


NSString* AppSupportDirectory()
{
    static NSString *sPath;
    if( ! sPath ) {
        NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                             NSUserDomainMask, YES)
                         objectAtIndex: 0];
        dir = [dir stringByAppendingPathComponent: [[NSBundle mainBundle] bundleIdentifier]];
        if( ! [[NSFileManager defaultManager] fileExistsAtPath: dir]
                && ! [[NSFileManager defaultManager] createDirectoryAtPath: dir attributes: nil] )
            [NSException raise: NSGenericException format: @"Unable to create app support dir %@",dir];
        sPath = [dir copy];
    }
    return sPath;
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
