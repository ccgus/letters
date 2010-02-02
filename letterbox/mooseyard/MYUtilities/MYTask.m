//
//  MYTask.m
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYTask.h"

//FIX: NOTICE: This code was written assuming garbage collection. It will currently leak like a sieve without it.

NSString* const MYTaskErrorDomain = @"MYTaskError";
NSString* const MYTaskExitCodeKey = @"MYTaskExitCode";
NSString* const MYTaskObjectKey = @"MYTask";

#define MYTaskSynchronousRunLoopMode @"MYTask"


@interface MYTask ()
@property (readwrite,nonatomic) BOOL isRunning;
@property (readwrite,retain,nonatomic) NSError *error;
- (void) _finishUp;
@end


@implementation MYTask


- (id) initWithCommand: (NSString*)command
             arguments: (NSArray*)arguments
{
    Assert(command);
    self = [super init];
    if (self != nil) {
        _command = command;
        _arguments = arguments ?[arguments mutableCopy] :[NSMutableArray array];
        _modes = [NSMutableArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil];
    }
    return self;
}


- (id) initWithCommand: (NSString*)command, ...
{
    NSMutableArray *arguments = [NSMutableArray array];
    va_list args;
    va_start(args,command);
    id arg;
    while( nil != (arg=va_arg(args,id)) )
        [arguments addObject: [arg description]];
    va_end(args);
    
    return [self initWithCommand: command arguments: arguments];
}


- (id) initWithError: (NSError*)error
{
    self = [super init];
    if( self ) {
        _error = error;
    }
    return self;
}


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@ %@", 
            _command, [_arguments componentsJoinedByString: @" "]];
}


- (void) addArgument: (id)argument
{
    [_arguments addObject: [argument description]];
}

- (void) addArgumentsFromArray: (NSArray*)arguments
{
    for( id arg in arguments )
        [_arguments addObject: [arg description]];
}

- (void) addArguments: (id)arg, ...
{
    va_list args;
    va_start(args,arg);
    while( arg ) {
        [_arguments addObject: [arg description]];
        arg = va_arg(args,id);
    }
    va_end(args);
}

- (void) prependArguments: (id)arg, ...
{
    va_list args;
    va_start(args,arg);
    int i=0;
    while( arg ) {
        [_arguments insertObject: [arg description] atIndex: i++];
        arg = va_arg(args,id);
    }
    va_end(args);
}


- (NSString*) commandLine {
    NSMutableString *desc = [NSMutableString stringWithString: _command];
    for (NSString *arg in _arguments) {
        [desc appendString: @" "];
        if ([arg rangeOfString: @" "].length > 0)
            arg = [NSString stringWithFormat: @"'%@'", arg];
        [desc appendString: arg];
    }
    return desc;
}


- (void) ignoreOutput
{
    _ignoreOutput = YES;
}


- (BOOL) makeError: (NSString*)fmt, ...
{
    va_list args;
    va_start(args,fmt);

    NSString *message = [[NSString alloc] initWithFormat: fmt arguments: args];
    LogTo(MYTask, @"Error: %@",message);
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObject: message
                                                                   forKey: NSLocalizedDescriptionKey];
    _error = [NSError errorWithDomain: MYTaskErrorDomain code: kMYTaskError userInfo: info];

    va_end(args);
    return NO;
}


- (NSPipe*) _openPipeAndHandle: (NSFileHandle**)handle notifying: (SEL)selector
{
    NSPipe *pipe = [NSPipe pipe];
    *handle = [pipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: selector
                                                 name: NSFileHandleReadCompletionNotification
                                               object: *handle];
    [*handle readInBackgroundAndNotifyForModes: _modes];
    return pipe;
}


- (void) _close
{
    // No need to call -closeFile on file handles obtained from NSPipe (in fact, it can hang)
    _outHandle = nil;
    _errHandle = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self 
                                                    name: NSFileHandleReadCompletionNotification
                                                  object: nil];
}


/** Subclasses can override this. */
- (NSTask*) createTask
{
    Assert(!_task,@"createTask called twice");
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = _command;
    task.arguments = _arguments;
    if( _currentDirectoryPath )
        task.currentDirectoryPath = _currentDirectoryPath;
    return task;
}    


- (BOOL) start
{
    Assert(!_task, @"Task has already been run");
    if( _error )
        return NO;
    
    _task = [self createTask];
    Assert(_task,@"createTask returned nil");
    
    LogTo(MYTask,@"$ %@", self.commandLine);
    
    _task.standardOutput = [self _openPipeAndHandle: &_outHandle notifying: @selector(_gotOutput:)];
    _outputData =  [[NSMutableData alloc] init];
    _task.standardError  = [self _openPipeAndHandle: &_errHandle notifying: @selector(_gotStderr:)];
    _errorData =  [[NSMutableData alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_exited:)
                                                 name: NSTaskDidTerminateNotification
                                               object: _task];
    
    @try{
        [_task launch];
    }@catch( id x ) {
        Warn(@"Task failed to launch: %@",x);
        _resultCode = 666;
        [self _close];
        return [self makeError: @"Exception launching %@: %@",_task.launchPath,x];
    }
    LogTo(MYTaskVerbose, @"Launched task, modes %@", _modes);
    Assert(_task.isRunning);
    _taskRunning = YES;
    self.isRunning = YES;
    
    return YES;
}


- (void) stop
{
    LogTo(MYTaskVerbose, @"Stopping task");
    [_task interrupt];
    [self _close];
    _taskRunning = NO;
    self.isRunning = NO;
}


- (BOOL) _shouldFinishUp
{
    return !_task.isRunning && (_ignoreOutput || (!_outHandle && !_errHandle));
}


- (void) _gotOutput: (NSNotification*)n
{
    NSData *data = [n.userInfo objectForKey: NSFileHandleNotificationDataItem];
    if( n.object == _outHandle ) {
        if( data.length > 0 ) {
            [_outHandle readInBackgroundAndNotifyForModes: _modes];
            LogTo(MYTaskVerbose, @"Got %u bytes of output",data.length);
            if( _outputData ) {
                [self willChangeValueForKey: @"output"];
                [self willChangeValueForKey: @"outputData"];
                [_outputData appendData: data];
                _output = nil;
                [self didChangeValueForKey: @"outputData"];
                [self didChangeValueForKey: @"output"];
            }
        } else {
            LogTo(MYTaskVerbose, @"Closed output");
            _outHandle = nil;
            if( [self _shouldFinishUp] )
                [self _finishUp];
        }
    }
}

- (void) _gotStderr: (NSNotification*)n
{
    if( n.object == _errHandle ) {
        NSData *data = [n.userInfo objectForKey: NSFileHandleNotificationDataItem];
        if( data.length > 0 ) {
            [_errHandle readInBackgroundAndNotifyForModes: _modes];
            LogTo(MYTaskVerbose, @"Got %u bytes of stderr",data.length);
            [self willChangeValueForKey: @"errorData"];
            [_errorData appendData: data];
            [self didChangeValueForKey: @"errorData"];
        } else {
            LogTo(MYTaskVerbose, @"Closed stderr");
            _errHandle = nil;
            if( [self _shouldFinishUp] )
                [self _finishUp];
        }
    }
}

- (void) _exited: (NSNotification*)n
{
    _resultCode = _task.terminationStatus;
    LogTo(MYTaskVerbose, @"Exited with result=%i",_resultCode);
    _taskRunning = NO;
    if( [self _shouldFinishUp] )
        [self _finishUp];
    else
        [self performSelector: @selector(_finishUp) withObject: nil afterDelay: 1.0];
}


- (void) _finishUp
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(_finishUp) object: nil];
    [self _close];

    LogTo(MYTaskVerbose, @"Finished!");

    if( _resultCode != 0 ) {
        // Handle errors:
        NSString *errStr = nil;
        if( _errorData.length > 0 )
            errStr = [[NSString alloc] initWithData: _errorData encoding: NSUTF8StringEncoding];
        LogTo(MYTask, @"    *** task returned %i: %@",_resultCode,errStr);
        if( errStr.length == 0 )
            errStr = [NSString stringWithFormat: @"Command returned status %i",_resultCode];
        NSString *desc = [NSString stringWithFormat: @"%@ command error", _task.launchPath.lastPathComponent];
        // For some reason the body text in the alert shown by -presentError: is taken from the
        // NSLocalizedRecoverySuggestionErrorKey, not the NSLocalizedFailureReasonKey...
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     desc,                                  NSLocalizedDescriptionKey,
                                     errStr,                                NSLocalizedRecoverySuggestionErrorKey,
                                     [NSNumber numberWithInt: _resultCode], MYTaskExitCodeKey,
                                     self,                                  MYTaskObjectKey,
                                     nil];
        self.error = [[NSError alloc] initWithDomain: MYTaskErrorDomain 
                                                code: kMYTaskError
                                            userInfo: info];
    }

    [self finished];

    self.isRunning = NO;
}

- (void) finished
{
    // This is a hook that subclasses can override to do post-processing.
}


- (BOOL) _waitTillFinishedInMode: (NSString*)runLoopMode
{
    // wait for task to exit:
    while( _task.isRunning || self.isRunning )
        if (![[NSRunLoop currentRunLoop] runMode: runLoopMode
                                      beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1.0]]) {
            // This happens if both stderr and stdout are closed (leaving no NSFileHandles running
            // in this runloop mode) but the task hasn't yet notified me that it exited.
            // For some reason, in 10.6 the notification sometimes just doesn't appear, so poll
            // for it:
            if (_task.isRunning) {
                Warn(@"MYTask _waitTillFinishedInMode: no runloop sources left for %@ mode; waiting...", runLoopMode);
                sleep(1);
            } else {
                Warn(@"MYTask _waitTillFinishedInMode: Task exited without notifying!");
                [self _exited: nil];
            }
        } else
            LogTo(MYTaskVerbose, @"..._waitTillFinishedInMode still waiting...");

    return (_resultCode==0);
}

- (BOOL) waitTillFinished
{
    return [self _waitTillFinishedInMode: _modes.lastObject];
}


- (BOOL) run
{
    [_modes addObject: MYTaskSynchronousRunLoopMode];
    return [self start] && [self _waitTillFinishedInMode: MYTaskSynchronousRunLoopMode];
    
}    


- (BOOL) run: (NSError**)outError
{
    BOOL result = [self run];
    if( outError ) *outError = self.error;
    return result;
}


@synthesize currentDirectoryPath=_currentDirectoryPath, outputData=_outputData, error=_error, isRunning=_isRunning;


- (NSString*) output
{
    if( ! _output && _outputData ) {
        _output = [[NSString alloc] initWithData: _outputData encoding: NSUTF8StringEncoding];
        // If output isn't valid UTF-8, fall back to CP1252, aka WinLatin1, a superset of ISO-Latin-1.
        if( ! _output ) {
            _output = [[NSString alloc] initWithData: _outputData encoding: NSWindowsCP1252StringEncoding];
            Warn(@"MYTask: Output of '%@' was not valid UTF-8; interpreting as CP1252",self);
        }
    }
    return _output;
}

- (NSString*) outputAndError
{
    NSString *result = self.output ?: @"";
    NSString *errorStr = nil;
    if( _error )
        errorStr = [NSString stringWithFormat: @"%@:\n%@",
                    _error.localizedDescription,_error.localizedRecoverySuggestion];
    else if( _errorData.length > 0 )
        errorStr = [[NSString alloc] initWithData: _errorData encoding: NSUTF8StringEncoding];
    if( errorStr )
        result = [NSString stringWithFormat: @"%@\n\n%@", errorStr,result];
    return result;
}

+ (NSArray*) keyPathsForValuesAffectingOutputAndError
{
    return [NSArray arrayWithObjects: @"output", @"error", @"errorData",nil];
}


@end
