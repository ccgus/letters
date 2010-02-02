//
//  FileUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 1/14/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


FOUNDATION_EXPORT OSStatus PathToFSRef( NSString *path, FSRef *outFSRef );
FOUNDATION_EXPORT OSStatus FSRefToPath( const FSRef *fsRef, NSString **outPath );

FOUNDATION_EXPORT BOOL CheckOSErr( OSStatus err, NSError **error );

FOUNDATION_EXPORT NSString* AppSupportDirectory(void);
