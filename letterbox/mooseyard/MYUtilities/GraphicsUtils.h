//
//  GraphicsUtils.h
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (MYUtilities)
- (NSImage*) my_shrunkToFitIn: (NSSize) maxSize;
- (NSSize) my_sizeOfLargestRep;
- (NSData*) my_JPEGData;
- (NSData*) my_dataInFormat: (NSBitmapImageFileType)format quality: (float)quality;
@end


@interface NSBezierPath (MYUtilities)
+ (NSBezierPath*) my_bezierPathWithRoundRect: (NSRect)rect radius: (float)radius;
@end


NSArray* OpenWindowsWithDelegateClass( Class klass );


/** Moves/resizes r to fit inside container */
NSRect PinRect( NSRect r, NSRect container );

OSStatus LoadFontsFromBundle( NSBundle *bundle );
OSStatus LoadFontsFromPath( NSString* path );
