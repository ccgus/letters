//
//  URLFormatter.h
//  Murky
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/** An NSURLFormatter for text fields that let the user enter URLs.
    The associated text field's objectValue will be an NSURL object. */
@interface MYURLFormatter : NSFormatter
{
    NSArray *_allowedSchemes;
}

@property (copy,nonatomic) NSArray *allowedSchemes;

+ (void) beginFilePickerFor: (NSTextField*)field;
+ (void) beginNewFilePickerFor: (NSTextField*)field;

@end
