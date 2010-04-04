//
//  LBMessage.h
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBMIMEParser.h"

@interface LBMessage : NSObject {
    
    // this can't be syntesized since we lazy load it.
    NSString *messageBody;
    
}

@property (retain) NSString *localUUID;
@property (retain) NSString *serverUID;
@property (retain) NSString *messageId;
@property (retain) NSString *inReplyTo;
@property (retain) NSString *mailbox;
@property (retain) NSString *subject;
@property (retain) NSString *sender;
@property (retain) NSString *to;
@property (retain) NSString *messageBody;
@property (retain) NSURL *messageURL;
@property (retain) NSDate *receivedDate;
@property (retain) NSDate *sendDate;

@property (assign) BOOL seenFlag;
@property (assign) BOOL answeredFlag;
@property (assign) BOOL flaggedFlag;
@property (assign) BOOL deletedFlag;
@property (assign) BOOL draftFlag;
@property (retain) NSString *flags;
@property (retain) LBMIMEMessage *mimePart;

- (void) parseHeaders;


@end
