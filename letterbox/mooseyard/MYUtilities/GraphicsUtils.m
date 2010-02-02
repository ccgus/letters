//
//  GraphicsUtils.m
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "GraphicsUtils.h"
#import "FileUtils.h"
#import <ApplicationServices/ApplicationServices.h>


@implementation NSImage (MYUtilities)


- (NSBitmapImageRep*) my_bitmapRep
{
    NSSize max = {0,0};
    NSBitmapImageRep *bestRep = nil;
    for( NSImageRep *rep in self.representations )
        if( [rep isKindOfClass: [NSBitmapImageRep class]] ) {
            NSSize size = [rep size];
            if( size.width > max.width || size.height > max.height ) {
                bestRep = (NSBitmapImageRep*)rep;
                max = size;
            }
        }
    if( ! bestRep ) {
        NSImage *tiffImage = [[NSImage alloc] initWithData:[self TIFFRepresentation]];
        bestRep = [[tiffImage representations] objectAtIndex:0];
        [tiffImage autorelease];
    }
    return bestRep;
}


- (NSSize) my_sizeOfLargestRep
{
    NSArray *reps = [self representations];
    NSSize max = {0,0};
    int i;
    for( i=[reps count]-1; i>=0; i-- ) {
        NSImageRep *rep = [reps objectAtIndex: i];
        NSSize size = [rep size];
        if( size.width > max.width || size.height > max.height ) {
            max = size;
        }
    }
    return max;
}


- (NSImage*) my_shrunkToFitIn: (NSSize) maxSize
{
    NSSize size = self.size;
    float scale = MIN( maxSize.width/size.width, maxSize.height/size.height );
    if( scale >= 1.0 )
        return self;
    
    NSSize newSize = {roundf(size.width*scale), roundf(size.height*scale)};
    NSImage *newImage = [[NSImage alloc] initWithSize: newSize];
    [newImage lockFocus];
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [context setImageInterpolation: NSImageInterpolationHigh];
    [self drawInRect: NSMakeRect(0,0,newSize.width,newSize.height)
            fromRect: NSMakeRect(0,0,size.width,size.height)
           operation: NSCompositeCopy fraction: 1.0f];
    [context restoreGraphicsState];
    [newImage unlockFocus];
    return [newImage autorelease];
}


- (NSData*) my_JPEGData
{
    return [self my_dataInFormat: NSJPEGFileType quality: 0.75f];
}


- (NSData*) my_dataInFormat: (NSBitmapImageFileType)format quality: (float)quality
{
    NSBitmapImageRep *rep = self.my_bitmapRep;
    NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithFloat: quality], NSImageCompressionFactor, nil];
    return [rep representationUsingType: format properties: props];
}


#if 0

// Adapted from Apple's CocoaCreateMovie sample
// <http://developer.apple.com/samplecode/Sample_Code/QuickTime/Basics/CocoaCreateMovie/MyController.m.htm>
static void CopyNSImageRepToGWorld(NSBitmapImageRep *imageRepresentation, GWorldPtr gWorldPtr)
{
    PixMapHandle  pixMapHandle;
    unsigned char*   pixBaseAddr;

    // Lock the pixels
    pixMapHandle = GetGWorldPixMap(gWorldPtr);
    LockPixels (pixMapHandle);
    pixBaseAddr = (unsigned char*) GetPixBaseAddr(pixMapHandle);

    const unsigned char* bitMapDataPtr = [imageRepresentation bitmapData];

    if ((bitMapDataPtr != nil) && (pixBaseAddr != nil))
    {
        int i,j;
        int pixmapRowBytes = GetPixRowBytes(pixMapHandle);
        NSSize imageSize = [imageRepresentation size];
        for (i=0; i< imageSize.height; i++)
        {
            const unsigned char *src = bitMapDataPtr + i * [imageRepresentation bytesPerRow];
            unsigned char *dst = pixBaseAddr + i * pixmapRowBytes;
            for (j = 0; j < imageSize.width; j++)
            {
                *dst++ = 0;  // X - our src is 24-bit only
                *dst++ = *src++; // Red component
                *dst++ = *src++; // Green component
                *dst++ = *src++; // Blue component
            }
        }
    }
    UnlockPixels(pixMapHandle);
}


- (NSData*) my_PICTData
{
    // Locate the bitmap image rep:
    NSBitmapImageRep *rep;
    NSEnumerator *e = [[self representations] objectEnumerator];
    while( (rep=[e nextObject]) != nil ) {
        if( [rep isKindOfClass: [NSBitmapImageRep class]] )
            break;
    }
    if( ! rep ) {
        Warn(@"No bitmap image rep in image");
        return nil;
    }

    // Copy the image data into a GWorld:
    Rect bounds;
    SetRect(&bounds, 0,0,[rep pixelsWide],[rep pixelsHigh]);    
    GWorldPtr gworld;
    OSStatus err = NewGWorld(&gworld, 32, &bounds, NULL, NULL, 0);
    if( err ) {
        Warn(@"NewGWorld failed with err %i",err);
        return nil;
    }
    CopyNSImageRepToGWorld(rep,gworld);

    // Draw the GWorld into a PicHandle:
    CGrafPtr oldPort;
    GDHandle oldDevice;
    GetGWorld(&oldPort,&oldDevice);
    SetGWorld(gworld,NULL);
    ClipRect(&bounds);
    PicHandle pic = OpenPicture(&bounds);
    CopyBits(GetPortBitMapForCopyBits(gworld),
             GetPortBitMapForCopyBits(gworld),
             &bounds,&bounds,srcCopy,NULL);
    ClosePicture();
    err = QDError();
    SetGWorld(oldPort,oldDevice);
    DisposeGWorld(gworld);
    
    if( err ) {
        Warn(@"Couldn't convert to PICT: error %i",err);
        return nil;
    }

    // Copy the PicHandle into an NSData:
    HLock((Handle)pic);
    //Test to put PICT on clipboard:
    /*ScrapRef scrap;
    GetCurrentScrap(&scrap);
    ClearScrap(&scrap);
    PutScrapFlavor(scrap,'PICT',0,GetHandleSize((Handle)pic),*pic);*/
    NSData *data = [NSData dataWithBytes: *pic length: GetHandleSize((Handle)pic)];
    DisposeHandle((Handle)pic);
    Log(@"Converted image to %i bytes of PICT data",[data length]);
    return data;
}
#endif


@end




@implementation NSBezierPath (MYUtilities)

+ (NSBezierPath*) my_bezierPathWithRoundRect: (NSRect)rect radius: (float)radius
{
    radius = MIN(radius, floorf(rect.size.width/2));
    float x0 = NSMinX(rect), y0 = NSMinY(rect),
          x1 = NSMaxX(rect), y1 = NSMaxY(rect);
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    [path moveToPoint: NSMakePoint(x0+radius,y0)];
    
    [path appendBezierPathWithArcFromPoint: NSMakePoint(x1,y0)
                                   toPoint: NSMakePoint(x1,y1) radius: radius];
    [path appendBezierPathWithArcFromPoint: NSMakePoint(x1,y1)
                                   toPoint: NSMakePoint(x0,y1) radius: radius];
    [path appendBezierPathWithArcFromPoint: NSMakePoint(x0,y1)
                                   toPoint: NSMakePoint(x0,y0) radius: radius];
    [path appendBezierPathWithArcFromPoint: NSMakePoint(x0,y0)
                                   toPoint: NSMakePoint(x1,y0) radius: radius];
    [path closePath];
    return path;
}

@end



NSArray* OpenWindowsWithDelegateClass( Class klass )
{
    NSMutableArray *windows = $marray();
    for( NSWindow *window in [NSApp windows] ) {
        id delegate = window.delegate;
        if( (window.isVisible || window.isMiniaturized) && (klass==nil || [delegate isKindOfClass: klass]) ) 
            [windows addObject: window];
    }
    return windows;
}    



NSRect PinRect( NSRect r, NSRect container )
{
    // Push r's origin inside container, and limit its size to the container's:
    r = NSMakeRect(MAX(r.origin.x, container.origin.x),
                   MAX(r.origin.y, container.origin.y),
                   MIN(r.size.width, container.size.width),
                   MIN(r.size.height, container.size.height));
    // Push r's outside edges into the container:
    r.origin.x -= MAX(0, NSMaxX(r)-NSMaxX(container));
    r.origin.y -= MAX(0, NSMaxY(r)-NSMaxY(container));
    return r;
    
}


OSStatus LoadFontsFromBundle( NSBundle *bundle )
{
    NSString *fontsPath = [[bundle resourcePath] stringByAppendingPathComponent:@"Fonts"];
    if( fontsPath )
        return LoadFontsFromPath(fontsPath);
    else
        return fnfErr;
}


OSStatus LoadFontsFromPath( NSString* path )
{
    // Tip of the hat to Buddy Kurz!
    FSRef fsRef;
    OSStatus err = PathToFSRef(path,&fsRef);
    if (err==noErr)
        err = ATSFontActivateFromFileReference(&fsRef,
                                               kATSFontContextLocal,
                                               kATSFontFormatUnspecified,
                                               NULL,
                                               kATSOptionFlagsDefault,
                                               NULL
                                               );
    if( err ) Warn(@"LoadFontsFromPath: Error %i for %@",err,path);
    return err;
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
