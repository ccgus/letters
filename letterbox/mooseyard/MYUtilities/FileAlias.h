//
//  FileAlias.h
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


/** A wrapper around an AliasHandle: a persistent reference to a file, which works
    even if the file is moved or renamed, or its volume unmounted. */

@interface FileAlias : NSObject <NSCoding>
{
    AliasHandle _alias;
}

- (id) initWithFilePath: (NSString*)path
                  error: (NSError**)error;

- (id) initWithFilePath: (NSString*)path 
         relativeToPath: (NSString*)fromPath
                  error: (NSError**)error;

- (NSString*) filePath: (NSError**)error;
- (NSString*) filePathRelativeToPath: (NSString*)fromPath error: (NSError**)error;

- (NSArray*) findMatchesRelativeToPath: (NSString*)fromPath 
                             withRules: (unsigned)rules      // rules = kARMSearch etc.
                                 error: (NSError**)error;
- (NSArray*) findMatches: (NSError**)error;

- (NSString*) originalPath;
- (NSString*) originalFilename;
- (NSString*) originalVolumeName;
- (void) dump;

@end
