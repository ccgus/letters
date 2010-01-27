//
//  LAActivityViewer.m
//  Letters
//
//  Created by August Mueller on 1/24/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAActivityViewer.h"
#import <LetterBox/LetterBox.h>

@interface LAActivityViewer ()
- (void) registerForNotifications;
@end


@implementation LAActivityViewer

+ (id)sharedActivityViewer {
    static LAActivityViewer *me = nil;
    
    if (!me) {
        
        me = [[self alloc] initWithWindowNibName:@"ActivityViewer"];
        [me setWindowFrameAutosaveName:@"ActivityViewer"];
        [[me window] setFrameAutosaveName:@"ActivityViewer"];
    }
    
    return me;
}

- (id)initWithWindowNibName:(NSString*)nibName {
    
    self = [super initWithWindowNibName:nibName];
    if (self != nil) {
        runningActivities = [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [runningActivities release];
    [super dealloc];
}

- (void)awakeFromNib {
    [activitiesTable setDataSource:self];
    [activitiesTable setDelegate:self];
    
    [self registerForNotifications];
}


- (void)registerForNotifications {
    
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LBActivityStartedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
     {
         
         id activity = [[note userInfo] objectForKey:@"activity"];
         if (activity) {
             [runningActivities addObject:activity];
             [activitiesTable reloadData];
         }
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LBActivityUpdatedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
     {
         [activitiesTable reloadData];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LBActivityEndedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note)
     {
         id activity = [[note userInfo] objectForKey:@"activity"];
         if (activity) {
             [runningActivities removeObject:activity];
             [activitiesTable reloadData];
         }
     }];
}


- (void)cancelAllActivities:(id)sender {
    
    for (id <LBActivity> activity in runningActivities) {
        [activity cancelActivity];
    }
    
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [runningActivities count];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex 
{
    id <LBActivity>activity = [runningActivities objectAtIndex:rowIndex];
    return [activity activityStatus];
}



@end
