//
//  FileAlias.m
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "FileAlias.h"
#import "FileUtils.h"


@implementation FileAlias


- (id) initWithFilePath: (NSString*)targetPath 
         relativeToPath: (NSString*)fromPath
                  error: (NSError**)error
{
    NSParameterAssert(targetPath);
    self = [super init];
    if( self ) {
        OSStatus err;
        FSRef fromRef, targetRef;
        err = PathToFSRef(targetPath, &targetRef);
        if( ! err ) {
            if( fromPath ) {
                err = PathToFSRef(fromPath,&fromRef);
                if( ! err )
                    err = FSNewAlias(&fromRef,&targetRef,&_alias);
            } else {
                err = FSNewAlias(NULL,&targetRef,&_alias);
            }
        }
        
        if( ! CheckOSErr(err,error) ) {
            Warn(@"FileAlias init failed with OSStatus %i for %@",err,targetPath);
            [self release];
            return nil;
        }
    }
    return self;
}

- (id) initWithFilePath: (NSString*)path
                  error: (NSError**)error
{
    return [self initWithFilePath: path relativeToPath: nil error: error];
}


- (void) dealloc
{
    if( _alias )
        DisposeHandle((Handle)_alias);
    [super dealloc];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    NSParameterAssert([coder allowsKeyedCoding]);
    NSKeyedArchiver *arch = (NSKeyedArchiver*)coder;

    [arch encodeBytes: (const uint8_t *) *_alias 
               length: GetHandleSize((Handle)_alias)
               forKey: @"aliasHandle"];
}


- (id)initWithCoder:(NSCoder *)decoder
{
    NSParameterAssert([decoder allowsKeyedCoding]);
    NSKeyedUnarchiver *arch = (NSKeyedUnarchiver*)decoder;

    self = [super init];
    if( self ) {
        Handle handle = NULL;
        unsigned length;
        const void *bytes = [arch decodeBytesForKey:@"aliasHandle" returnedLength: &length];
        if( bytes )
            PtrToHand(bytes,&handle,length);
        if( ! handle ) {
            [self release];
            return nil;
        }
        _alias = (AliasHandle) handle;
    }
    return self;
}


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@['%@']", [self class],[self originalFilename]];
}


- (NSString*) originalPath
{
    CFStringRef path = NULL;
    OSStatus err = FSCopyAliasInfo(_alias,NULL,NULL,&path,NULL,NULL);
    if( err )
        return nil;
    else
        return [(id)path autorelease];
}

- (NSString*) originalFilename
{
    HFSUniStr255 targetName;
    OSStatus err = FSCopyAliasInfo(_alias,&targetName,NULL,NULL,NULL,NULL);
    if( err )
        return nil;
    else
        return [(id)FSCreateStringFromHFSUniStr(NULL,&targetName) autorelease];
}

- (NSString*) originalVolumeName
{
    HFSUniStr255 volName;
    OSStatus err = FSCopyAliasInfo(_alias,NULL,&volName,NULL,NULL,NULL);
    if( err )
        return nil;
    else
        return [(id)FSCreateStringFromHFSUniStr(NULL,&volName) autorelease];
}

- (void) dump
{
    HFSUniStr255 targetName,volName;
    CFStringRef path;
    FSAliasInfoBitmap whichInfo = 0;
    FSAliasInfo info;
    OSStatus err = FSCopyAliasInfo(_alias,&targetName,&volName,&path,&whichInfo,&info);
    if( err ) {
        NSLog(@"FSCopyAliasInfo returned error %i",err);
        return;
    }
    NSString *str = (id)FSCreateStringFromHFSUniStr(NULL,&targetName);
    NSLog(@"Target name = '%@'",str);
    [str release];
    str = (id)FSCreateStringFromHFSUniStr(NULL,&volName);
    NSLog(@"Volume name = '%@'",str);
    [str release];
    NSLog(@"Path        = %@",path);
    if( path ) CFRelease(path);
    NSLog(@"Info bitmap = %08X", whichInfo);
}    


#pragma mark -
#pragma mark RESOLVING:


- (NSString*) filePathRelativeToPath: (NSString*)fromPath error: (NSError**)error
{
    FSRef fromRef, targetRef, *fromRefPtr;
    if( fromPath ) {
        if( ! CheckOSErr( PathToFSRef(fromPath,&fromRef), error ) )
            return NO;
        fromRefPtr = &fromRef;
    } else {
        fromRefPtr = NULL;
    }
    
    Boolean wasChanged;
    NSString *targetPath;
    if( CheckOSErr( FSResolveAlias(fromRefPtr,_alias,&targetRef,&wasChanged), error)
            && CheckOSErr( FSRefToPath(&targetRef,&targetPath), error ) )
        return targetPath;
    else {
        NSLog(@"%@: Couldn't resolve alias!",self);
        [self dump];
        return nil;
    }
}

- (NSString*) filePath: (NSError**)error
{
    return [self filePathRelativeToPath: nil error: error];
}


- (NSArray*) findMatchesRelativeToPath: (NSString*)fromPath 
                             withRules: (unsigned)rules
                                 error: (NSError**)error
{
    FSRef fromRef, *fromRefPtr;
    if( fromPath ) {
        if( ! CheckOSErr( PathToFSRef(fromPath,&fromRef), error ) )
            return nil;
        fromRefPtr = &fromRef;
    } else {
        fromRefPtr = NULL;
    }
    
    Boolean wasChanged;
    short count = 10;
    FSRef matches[count];
    
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
    if( ! CheckOSErr( FSMatchAliasBulk(fromRefPtr, rules, _alias, &count, matches, &wasChanged, NULL, NULL), error) ) {
        NSLog(@"%@: FSMatchAliasBulk failed!",self);
        return nil;
    }
#else
    if( ! CheckOSErr( FSMatchAlias(fromRefPtr,rules,_alias,&count,matches,&wasChanged,NULL,NULL), error) ) {
        NSLog(@"%@: FSMatchAlias failed!",self);
        return nil;
    }
#endif
    
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity: count];
    for( short i=0; i<count; i++ ) {
        NSString *path;
        if( FSRefToPath(&matches[i],&path) == noErr )
            [paths addObject: path];
    }
    return paths;
}


- (NSArray*) findMatches: (NSError**)error
{
    return [self findMatchesRelativeToPath: nil
                                 withRules: kARMMultVols | kARMSearch | kARMSearchMore | kARMTryFileIDFirst
                                     error: error];
}


@end


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
