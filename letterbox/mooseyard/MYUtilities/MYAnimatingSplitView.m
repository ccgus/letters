//
//  MYAnimatingSplitView.m
//  Cloudy
//
//  Created by Jens Alfke on 7/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYAnimatingSplitView.h"
#import "DateUtils.h"


#define kDefaultAnimationTime 0.3


@interface MYAnimatingSplitView ()
@property (readwrite) BOOL isLiveResizing;
@end


@implementation MYAnimatingSplitView


@synthesize animationTime=_animationTime;


- (void) my_animateDividerToPosition: (float)pos
{
    const NSTimeInterval maxTime = _animationTime ?: kDefaultAnimationTime;
    
    NSTimeInterval startTime = TimeIntervalSinceBoot();
    float startPos = self.dividerPosition;
    const NSTimeInterval animationTime = maxTime * fabs(pos-startPos)/self.frame.size.height;
    float fract;
    do {
        fract = (float) MIN(1.0, (TimeIntervalSinceBoot()-startTime)/animationTime);
        float curPos = startPos + fract*(pos-startPos);
        [self setPosition: curPos ofDividerAtIndex: 0];
        [self.window displayIfNeeded];
        [self.window update];
    }while( fract < 1.0 );
}


- (void) getDividerPositionMin: (float*)outMin max: (float*)outMax
{
    *outMin = [self.delegate splitView: self 
                    constrainMinCoordinate: [self minPossiblePositionOfDividerAtIndex: 0]
                    ofSubviewAt: 0];
    *outMax = [self.delegate splitView: self 
                    constrainMaxCoordinate: [self maxPossiblePositionOfDividerAtIndex: 0]
                    ofSubviewAt: 0];
}

- (float) dividerPosition
{
    return NSMaxY([[self.subviews objectAtIndex: 0] frame]);
}

- (void) setDividerPosition: (float)pos
{
    float minPos,maxPos;
    [self getDividerPositionMin: &minPos max: &maxPos];
    NSView *targetView = [[self subviews] objectAtIndex:0];
    NSRect startFrame = [targetView frame];

    // First uncollapse any collapsed subview:
    if( [self isSubviewCollapsed: targetView] )
        [self setPosition: minPos ofDividerAtIndex: 0];
    else if( startFrame.size.height > maxPos )
        [self setPosition: maxPos ofDividerAtIndex: 0];
    // Now animate:
    [self my_animateDividerToPosition: pos];
}

- (float) dividerFractionalPosition
{
    float minPos, maxPos, pos=self.dividerPosition;
    [self getDividerPositionMin: &minPos max: &maxPos];
    float denom = maxPos-minPos;
    if( denom<=0 )
        return 0.0f;
    else
        return (pos-minPos)/denom;
}

- (void) setDividerFractionalPosition: (float)fract
{
    float minPos, maxPos;
    [self getDividerPositionMin: &minPos max: &maxPos];
    self.dividerPosition = roundf( minPos + fract*(maxPos-minPos) );
}


- (void) collapseSubviewAtIndex: (int)index animate: (BOOL)animate
{
    if( ! [self isSubviewCollapsed: [self.subviews objectAtIndex: index]] ) {
        float pos = index==0 ?[self minPossiblePositionOfDividerAtIndex: 0]
                             :[self maxPossiblePositionOfDividerAtIndex: 0];
        if( animate )
            [self my_animateDividerToPosition: pos];
        else
            [self setPosition: pos ofDividerAtIndex: 0];
    }
}

- (void) collapseSubviewAtIndex: (int)index
{
    [self collapseSubviewAtIndex: index animate: YES];
}



- (BOOL) isLiveResizing
{
    return _isLiveResizing;
}

- (void) setIsLiveResizing: (BOOL)inLiveResize
{
    _isLiveResizing = inLiveResize;
    id delegate = self.delegate;
    if( [delegate respondsToSelector: @selector(splitView:inLiveResize:)] )
        [delegate splitView: self inLiveResize: inLiveResize];
}


- (void)viewWillStartLiveResize
{
    [super viewWillStartLiveResize];
    self.isLiveResizing = YES;
}

- (void) viewDidEndLiveResize
{
    [super viewDidEndLiveResize];
    self.isLiveResizing = NO;
}

@end
