//
//  LBActivity.h
//  LetterBox
//
//  Created by August Mueller on 1/24/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *LBActivityStartedNotification;
extern NSString *LBActivityUpdatedNotification;
extern NSString *LBActivityEndedNotification;

@protocol LBActivity <NSObject>

// this would be some sort of enum I think.  Indeterminate/whatever?
- (int) activityType;
- (NSString*) activityStatus;
- (void) cancelActivity;

@end
