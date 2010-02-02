//
//  IChatUtils.m
//  MYUtilities
//
//  Created by Jens Alfke on 3/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "IChatUtils.h"
#import "iChatBridge.h"
#import <InstantMessage/IMService.h>

@implementation IChatUtils


static iChatApplication *sIChatApp;

+ (void) initialize
{
    if( ! sIChatApp ) {
        sIChatApp = [SBApplication applicationWithBundleIdentifier: @"com.apple.iChat"];
        sIChatApp.timeout = 5*60; // in ticks
    }
}


+ (SBApplication*) app  {return sIChatApp;}
+ (BOOL) isRunning      {return sIChatApp.isRunning;}
+ (void) activate       {[sIChatApp activate];}


+ (iChatTextChat*) activeChat
{
    if( ! [sIChatApp isRunning] )
        return nil;
    SBElementArray *chats = sIChatApp.textChats;
    if( chats.count==0 )
        return nil;
    iChatTextChat *chat = [chats objectAtIndex: 0];
    /*if( ! chat.active )               // somehow this returns NO for Bonjour chats
        return nil;*/
    return chat;
}    

+ (NSString*) activeChatPartner
{
    iChatTextChat *chat = [self activeChat];
    Log(@"Active chat = %@",chat);
    if( ! chat )
        return nil;
    NSMutableArray *names = $marray();
    for( iChatBuddy *b in [chat participants] )
        [names addObject: (b.fullName ?: b.name)];
    Log(@"Particpants = %@",names);
    return [names componentsJoinedByString: @", "];
}

+ (BOOL) sendMessage: (NSString*)msg
{
    iChatTextChat *chat = [self activeChat];
    if( ! chat )
        return NO;
    [sIChatApp send: msg to: chat];
    return YES;
}

+ (NSDictionary*) iChatInfoForOnlinePerson: (ABPerson*)abPerson
{
    if( ! abPerson )
        return nil;
    IMPersonStatus bestStatus = IMPersonStatusOffline;
    NSDictionary *bestInfo = nil;
    for( IMService *service in [IMService allServices] ) {
        for( NSString *name in [service screenNamesForPerson: abPerson] ) {
            NSDictionary *info = [service infoForScreenName: name];
            if( [[info objectForKey: IMPersonCapabilitiesKey] containsObject: IMCapabilityText] ) {
                IMPersonStatus status = [[info objectForKey: IMPersonStatusKey] intValue];
                if( IMComparePersonStatus(status,bestStatus) < 0 ) {    // yes, it returns the wrong sign
                    bestInfo = info;
                    bestStatus = status;
                }
            }
        }
    }
    return bestInfo;
}

+ (BOOL) isPersonOnline: (ABPerson*)abPerson
{
    return [self iChatInfoForOnlinePerson: abPerson] != nil;
}

+ (iChatBuddy*) buddyWithScreenName: (NSString*)screenName
{
    NSPredicate *pred = [NSPredicate predicateWithFormat: @"handle==%@", screenName];
    @try{
        return [[[[sIChatApp buddies] filteredArrayUsingPredicate: pred] objectAtIndex: 0] get];
    } @catch( NSException *x ) {
        Log(@"buddyWithScreenName got exception: %@",x);
    }
    return nil;
}

+ (iChatBuddy*) buddyWithInfo: (NSDictionary*)info
{
    return [self buddyWithScreenName: [info objectForKey: IMPersonScreenNameKey]];
}

+ (BOOL) sendMessage: (NSString*)msg toPerson: (ABPerson*)abPerson
{
    NSDictionary *info = [self iChatInfoForOnlinePerson: abPerson];
    if( info ) {
        iChatBuddy *buddy = [self buddyWithInfo: info];
        if( buddy ) {
            [sIChatApp send: msg to: buddy];
            return YES;
        }
    } 
    return NO;
}


+ (BOOL) sendMessage: (NSString*)msg toBuddyWithScreenName: (NSString*)screenName
{
    iChatBuddy *buddy = [self buddyWithScreenName: screenName];
    if( buddy ) {
        @try{
            [sIChatApp send: msg to: buddy];
            return YES;
        } @catch( NSException *x ) {
            Log(@"sendMessage:toBuddyWithScreenName: got exception: %@",x);
        }
    } 
    return NO;
}


@end


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
