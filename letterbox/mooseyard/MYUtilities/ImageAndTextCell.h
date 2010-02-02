#import <Cocoa/Cocoa.h>

/** Subclass of NSTextFieldCell which can display text and an image simultaneously.
    Taken directly from Apple sample code. */
@interface ImageAndTextCell : NSTextFieldCell
{
    @private
    NSImage *image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
