//
//  IChatUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 3/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SBApplication, ABPerson;


@interface IChatUtils : NSObject 

+ (SBApplication*) app;
+ (BOOL) isRunning;
+ (void) activate;
+ (NSString*) activeChatPartner;
+ (BOOL) sendMessage: (NSString*)msg;

+ (NSDictionary*) iChatInfoForOnlinePerson: (ABPerson*)abPerson;
+ (BOOL) isPersonOnline: (ABPerson*)abPerson;

+ (BOOL) sendMessage: (NSString*)msg toPerson: (ABPerson*)abPerson;
+ (BOOL) sendMessage: (NSString*)msg toBuddyWithScreenName: (NSString*)screenName;

@end
