//
//  MYTask.h
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const MYTaskErrorDomain;
extern NSString* const MYTaskExitCodeKey;
extern NSString* const MYTaskObjectKey;
enum {
    kMYTaskError = 2
};



@interface MYTask : NSObject 
{
    @private
    NSString *_command;
    NSMutableArray *_arguments;
    NSString *_currentDirectoryPath;
    NSTask *_task;
    int _resultCode;
    NSError *_error;
    BOOL _ignoreOutput;
    NSFileHandle *_outHandle, *_errHandle;
    NSMutableData *_outputData, *_errorData;
    NSString *_output;
    NSMutableArray *_modes;
    BOOL _isRunning, _taskRunning;
}

- (id) initWithCommand: (NSString*)subcommand, ... NS_REQUIRES_NIL_TERMINATION;

/* designated initializer (subclasses can override) */
- (id) initWithCommand: (NSString*)subcommand
             arguments: (NSArray*)arguments;

- (id) initWithError: (NSError*)error;

- (void) addArgument: (id)argument;
- (void) addArguments: (id)arg1, ... NS_REQUIRES_NIL_TERMINATION;
- (void) addArgumentsFromArray: (NSArray*)arguments;
- (void) prependArguments: (id)arg1, ... NS_REQUIRES_NIL_TERMINATION;

- (void) ignoreOutput;

@property (copy) NSString* currentDirectoryPath;

/** Prettified description of command string. Doesn't do full shell-style quoting, though. */
- (NSString*) commandLine;

- (BOOL) run;
- (BOOL) run: (NSError**)outError;

- (BOOL) start;
- (void) stop;
- (BOOL) waitTillFinished;

@property (readonly,nonatomic) BOOL isRunning;
@property (readonly,retain,nonatomic) NSError* error;
@property (readonly,nonatomic) NSString *output, *outputAndError;
@property (readonly,nonatomic) NSData *outputData;

// protected:

/** Subclasses can override this to add arguments or customize the task */
- (NSTask*) createTask;

/** Sets the error based on the message and parameters. Always returns NO. */
- (BOOL) makeError: (NSString*)fmt, ...;

/** Called when the task finishes, just before the isRunning property changes back to NO.
    You can override this to do your own post-processing. */
- (void) finished;

@end
