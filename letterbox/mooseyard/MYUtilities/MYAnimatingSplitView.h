//
//  MYAnimatingSplitView.h
//  Cloudy
//
//  Created by Jens Alfke on 7/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <AppKit/NSSplitView.h>


@interface MYAnimatingSplitView : NSSplitView
{
    NSTimeInterval _animationTime;
    BOOL _isLiveResizing;
}


/** The maximum time it will take to animate the divider. (Actual time depends on distance moved.) */
@property NSTimeInterval animationTime;

/** Pixel position of the divider (in the splitview's bounds' coordinate system.)
    Setting this property animates the divider to the new position. */
@property float dividerPosition;

/** Position of the divider, scaled to the range [0..1]. */
@property float dividerFractionalPosition;

- (void) collapseSubviewAtIndex: (int)index;
- (void) collapseSubviewAtIndex: (int)index animate: (BOOL)animate;

/** Returns YES while the splitview itself is being resized (i.e. while the window
    is resizing, or a parent splitview is moving its divider.) */
@property (readonly) BOOL isLiveResizing;

@end


@interface NSObject (MYAnimatingSplitViewDelegate)
/** If the delegate implements this method, it will be called when the splitview
    begins and ends live resizing. */
- (void)splitView: (NSSplitView*)splitView inLiveResize: (BOOL)inLiveResize;
@end
