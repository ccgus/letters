//
//  LAMessageListView.m
//  Letters
//
//  Created by August Mueller on 2/20/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAMessageListView.h"


@implementation LAMessageListView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    
    if ([[self window] firstResponder] != self) {
        return [super performKeyEquivalent:theEvent];
    }
    
    NSString *chars = [theEvent charactersIgnoringModifiers];
    
    if ([theEvent type] == NSKeyDown && [chars length] == 1) {
        
        int val = [chars characterAtIndex:0];
        
        // check for a delete
        if (val == 127 || val == 63272) {
            if ([[self delegate] respondsToSelector:@selector(tableViewDidRecieveDeleteKey:)]) {
                return [(id)[self delegate] tableViewDidRecieveDeleteKey:self];
            }
        }
        
        // check for the enter / space to open it up
        else if (val == 13 /*return*/ || val == 32 /*space bar*/) {
            
            if ([[self delegate] respondsToSelector:@selector(tableViewDidRecieveEnterOrSpaceKey:)]) {
                return [(id)[self delegate] tableViewDidRecieveEnterOrSpaceKey:self];
            }
        }
    }
    
    return [super performKeyEquivalent:theEvent];
}
@end
