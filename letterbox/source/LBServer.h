//
//  LBServer.h
//  LetterBox
//
//  Created by August Mueller on 1/20/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libetpan/libetpan.h>


@class LBAccount;
@class LBFolder;
@class FMDatabase;


@interface LBServer : NSObject {
    LBAccount *_account;
        
    
    NSURL               *_baseCacheURL;
    NSURL               *_accountCacheURL;
    FMDatabase          *_cacheDB;
}

@property (retain) LBAccount *account;
@property (retain) NSURL *baseCacheURL;
@property (retain) NSURL *accountCacheURL;


- (id) initWithAccount:(LBAccount*)anAccount usingCacheFolder:(NSURL*)cacheFileURL;



@end
