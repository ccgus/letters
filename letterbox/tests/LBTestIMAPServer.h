//
//  LBTestIMAPServer.h
//  LetterBox
//
//  Created by August Mueller on 2/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPListener.h"
#import <GHUnit/GHUnit.h>

@interface LBTestIMAPServer : GHTestCase <TCPListenerDelegate> {
    TCPListener *listener;
    
    NSMutableArray *acceptList;
    NSMutableArray *responseList;
    
    NSMutableString *readString;
    
}

+ (id)sharedIMAPServer;
- (void)runScript:(NSString*)pathToScript;

@end
