//
//  URLFormatter.m
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYURLFormatter.h"


@implementation MYURLFormatter

@synthesize allowedSchemes=_allowedSchemes;


- (id) init
{
    self = [super init];
    if (self != nil) {
        _allowedSchemes = [[NSArray alloc] initWithObjects: @"http",@"https",@"file",@"ssh",nil];
    }
    return self;
}

- (void) dealloc
{
    [_allowedSchemes release];
    [super dealloc];
}


- (NSString *)stringForObjectValue:(id)obj
{
    if( ! [obj isKindOfClass: [NSURL class]] )
        return @"";
    else if( [obj isFileURL] )
        return [obj path];
    else
        return [obj absoluteString];
}


- (BOOL)getObjectValue:(id *)obj forString:(NSString *)str errorDescription:(NSString **)outError
{
    *obj = nil;
    NSString *error = nil;
    if( str.length==0 ) {
    } else if( [str hasPrefix: @"/"] ) {
        *obj = [NSURL fileURLWithPath: str];
        if( ! *obj )
            error = @"Invalid filesystem path";
    } else {
        NSURL *url = [NSURL URLWithString: str];
        NSString *scheme = [url scheme];
        if( url && scheme == nil ) {
            if( [str rangeOfString: @"."].length > 0 ) {
                // Turn "foo.com/bar" into "http://foo.com/bar":
                str = [@"http://" stringByAppendingString: str];
                url = [NSURL URLWithString: str];
                scheme = [url scheme];
            } else
                url = nil;
        }
        if( ! url || ! [url path] || url.host.length==0 ) {
            error = @"Invalid URL";
        } else if( _allowedSchemes && ! [_allowedSchemes containsObject: scheme] ) {
            error = [@"URL protocol must be %@" stringByAppendingString:
                                    [_allowedSchemes componentsJoinedByString: @", "]];
        }
        *obj = url;
    }
    if( outError ) *outError = error;
    return (error==nil);
}


+ (void) beginFilePickerFor: (NSTextField*)field
{
    NSParameterAssert(field);
    NSOpenPanel *open = [NSOpenPanel openPanel];
    open.canChooseDirectories = YES;
    open.canChooseFiles = NO;
    open.requiredFileType = (id)kUTTypeDirectory;
    [open beginSheetForDirectory: nil
                            file: nil
                  modalForWindow: field.window
                   modalDelegate: self
                  didEndSelector: @selector(_filePickerDidEnd:returnCode:context:)
                     contextInfo: field];
}

+ (void) beginNewFilePickerFor: (NSTextField*)field
{
    NSParameterAssert(field);
    NSSavePanel *save = [NSSavePanel savePanel];
    [save beginSheetForDirectory: nil
                            file: nil
                  modalForWindow: field.window
                   modalDelegate: self
                  didEndSelector: @selector(_filePickerDidEnd:returnCode:context:)
                     contextInfo: field];
}

+ (void) _filePickerDidEnd: (NSSavePanel*)save returnCode: (int)returnCode context: (void*)context
{
    [save orderOut: self];
    if( returnCode == NSOKButton ) {
        NSTextField *field = context;
        field.objectValue = [NSURL fileURLWithPath: save.filename];
    }
}


@end
