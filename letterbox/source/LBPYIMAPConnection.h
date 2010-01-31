//
//  LBPYIMAPConnection.h
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBActivity.h"
#import "LBIMAPConnection.h"

@class LBFolder;
@class LBAccount;
@class IMAPFetcher;

@interface LBPYIMAPConnection : LBIMAPConnection <LBActivity> {
    
    IMAPFetcher         *imapFetcher;
    
}

@property (assign) BOOL shouldCancelActivity;



@end
