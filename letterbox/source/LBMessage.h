//
//  LBMessage.h
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LBMessage : NSObject {
    
    // this can't be syntesized since we lazy load it.
    NSString *messageBody;
    
}

@property (retain) NSString *uuid;
@property (retain) NSString *messageId;
@property (retain) NSString *subject;
@property (retain) NSString *sender;
@property (retain) NSString *to;
@property (retain) NSString *messageBody;
@property (retain) NSURL *messageURL;
@property (retain) NSDate *receivedDate;
@property (retain) NSDate *sendDate;

- (void) parseHeaders;


@end
