//
//  MYDirectoryWatcher.m
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYDirectoryWatcher.h"
#import "Test.h"
#import "Logging.h"
#import <CoreServices/CoreServices.h>


static void directoryWatcherCallback(ConstFSEventStreamRef streamRef,
                                     void *clientCallBackInfo,
                                     size_t numEvents,
                                     void *eventPaths,
                                     const FSEventStreamEventFlags eventFlags[],
                                     const FSEventStreamEventId eventIds[]);

@interface MYDirectoryEvent ()
- (id) _initWithWatcher: (MYDirectoryWatcher*)itsWatcher
                   path: (NSString*)itsPath 
                  flags: (FSEventStreamEventFlags)itsFlags
                eventID: (FSEventStreamEventId)itsEventID;
@end


@implementation MYDirectoryWatcher


- (id) initWithDirectory: (NSString*)path target: (id)target action: (SEL)action
{
    Assert(path!=nil);
    self = [super init];
    if (self != nil) {
        _path = path.copy;
        // stringByStandardizingPath is supposed to resolve symlinks, but in 10.6 this seems to have stopped happening...
        _standardizedPath = [[[path stringByResolvingSymlinksInPath] stringByStandardizingPath] copy];
        _target = target;
        _action = action;
        _latency = 5.0;
        _lastEventID = kFSEventStreamEventIdSinceNow;
    }
    return self;
}

- (void) dealloc
{
    [self stop];
    [_path release];
    [_standardizedPath release];
    [super dealloc];
}

- (void) finalize
{
    [self stop];
    [super finalize];
}


@synthesize path=_path, latency=_latency, lastEventID=_lastEventID;

- (NSString*) standardizedPath {
    return _standardizedPath;
}


- (BOOL) start
{
    if( ! _stream ) {
        FSEventStreamContext context = {0,self,NULL,NULL,NULL};
        _stream = FSEventStreamCreate(NULL, 
                                      &directoryWatcherCallback, &context,
                                      (CFArrayRef)[NSArray arrayWithObject: _path], 
                                      _lastEventID, 
                                      _latency, 
                                      kFSEventStreamCreateFlagUseCFTypes);
        if( ! _stream )
            return NO;
        FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        if( ! FSEventStreamStart(_stream) ) {
            [self stop];
            return NO;
        }
        _historyDone = (_lastEventID == kFSEventStreamEventIdSinceNow);
        LogTo(MYDirectoryWatcher, @"Started on %@ (latency=%g, lastEvent=%llu)",_path,_latency,_lastEventID);
    }
    return YES;
}

- (void) pause
{
    if( _stream ) {
        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream);
        FSEventStreamRelease(_stream);
        _stream = NULL;
        LogTo(MYDirectoryWatcher, @"Stopped on %@ (lastEvent=%llu)",_path,_lastEventID);
    }
}

- (void) stop
{
    [self pause];
    _lastEventID = kFSEventStreamEventIdSinceNow;   // so events from now till next start will be dropped
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(start) object: nil];
}

- (void) stopTemporarily
{
    if( _stream ) {
        [self stop];
        [self performSelector: @selector(start) withObject: nil afterDelay: 0.0];
    }
}


- (void) _notifyEvents: (size_t)numEvents
                 paths: (NSArray*)paths
                 flags: (const FSEventStreamEventFlags[])eventFlags
              eventIDs: (const FSEventStreamEventId[])eventIDs
{
    for (size_t i=0; i<numEvents; i++) {
        NSString *path = [paths objectAtIndex: i];
        FSEventStreamEventFlags flags = eventFlags[i];
        FSEventStreamEventId eventID = eventIDs[i];
        if( flags & (kFSEventStreamEventFlagMount | kFSEventStreamEventFlagUnmount) ) {
            if( flags & kFSEventStreamEventFlagMount )
                LogTo(MYDirectoryWatcher, @"Volume mounted: %@",path);
            else
                LogTo(MYDirectoryWatcher, @"Volume unmounted: %@",path);
        } else if( flags & kFSEventStreamEventFlagHistoryDone ) {
            LogTo(MYDirectoryWatcher, @"Event #%llu History done",eventID);
            _historyDone = YES;
        } else {
            LogTo(MYDirectoryWatcher, @"Event #%llu flags=%02x path=%@",eventID,flags,path);
            if( _historyDone )
                flags |= kFSEventStreamEventFlagHistoryDone;
            
            MYDirectoryEvent *event = [[MYDirectoryEvent alloc] _initWithWatcher: self
                                                                        path: path 
                                                                       flags: flags
                                                                     eventID: eventID];
            [_target performSelector: _action withObject: event];
            [event release];
        }
        _lastEventID = eventIDs[i];
    }
}


static void directoryWatcherCallback(ConstFSEventStreamRef streamRef,
                                     void *watcher,
                                     size_t numEvents,
                                     void *eventPaths,
                                     const FSEventStreamEventFlags eventFlags[],
                                     const FSEventStreamEventId eventIDs[])
{
    [(MYDirectoryWatcher*)watcher _notifyEvents: numEvents
                                          paths: (NSArray*)eventPaths
                                          flags: eventFlags
                                       eventIDs: eventIDs];
}



@end




@implementation MYDirectoryEvent

- (id) _initWithWatcher: (MYDirectoryWatcher*)itsWatcher
                   path: (NSString*)itsPath 
                  flags: (FSEventStreamEventFlags)itsFlags
                eventID: (FSEventStreamEventId)itsEventID
{
    self = [super init];
    if (self != nil) {
        watcher = itsWatcher;
        path = itsPath.copy;
        flags = itsFlags;
        eventID = itsEventID;
    }
    return self;
}

- (void) dealloc
{
    [path release];
    [super dealloc];
}

@synthesize watcher,path,flags,eventID;

- (NSString*) relativePath
{
    NSString *base = watcher.standardizedPath;
    // stringByStandardizingPath is supposed to resolve symlinks, but in 10.6 this seems to have stopped happening...
    NSString *standardizedPath = [[path stringByResolvingSymlinksInPath] stringByStandardizingPath];
    if( ! [standardizedPath hasPrefix: base] )
        return nil;
    unsigned length = base.length;
    while( length < standardizedPath.length && [standardizedPath characterAtIndex: length]=='/' )
        length++;
    return [standardizedPath substringFromIndex: length];
}

- (BOOL) mustScanSubdirectories     {return (flags & kFSEventStreamEventFlagMustScanSubDirs) != 0;}
- (BOOL) eventsWereDropped          {return (flags & (kFSEventStreamEventFlagUserDropped|kFSEventStreamEventFlagKernelDropped)) != 0;}
- (BOOL) isHistorical               {return (flags & kFSEventStreamEventFlagHistoryDone)==0;}
- (BOOL) rootChanged                {return (flags & kFSEventStreamEventFlagRootChanged)!=0;}

@end