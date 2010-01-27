//
//  LAActivityViewer.h
//  Letters
//
//  Created by August Mueller on 1/24/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LAActivityViewer : NSWindowController <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTableView *activitiesTable;
    
    NSMutableArray *runningActivities;
}

+ (id)sharedActivityViewer;

- (void)cancelAllActivities:(id)sender;

@end
