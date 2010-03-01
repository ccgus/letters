//
//  LBMessage.m
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBMessage.h"
#import "LetterBoxUtilities.h"

@implementation LBMessage


@synthesize localUUID;
@synthesize serverUID;
@synthesize messageId;
@synthesize inReplyTo;
@synthesize mailbox;
@synthesize subject;
@synthesize sender;
@synthesize to;
@synthesize messageBody;
@synthesize messageURL;
@synthesize receivedDate;
@synthesize sendDate;

@synthesize seenFlag;
@synthesize answeredFlag;
@synthesize flaggedFlag;
@synthesize deletedFlag;
@synthesize draftFlag;
@synthesize flags;

- (id)initWithURL:(NSURL*)fileURL {
	self = [super init];
	if (self != nil) {
		self.messageURL = fileURL;
	}
    
	return self;
}

- (void)dealloc {
    
    LBRelease(localUUID);
    LBRelease(serverUID);
    LBRelease(messageId);
    LBRelease(inReplyTo);
    LBRelease(mailbox);
    LBRelease(subject);
    LBRelease(sender);
    LBRelease(to);
    LBRelease(messageBody);
    LBRelease(messageURL);
    LBRelease(receivedDate);
    LBRelease(sendDate);
    LBRelease(flags);
    
    [super dealloc];
}

- (void) parseHeaders {
    
    if (!subject) {
        self.subject = [messageURL lastPathComponent];
        
        
        // um.. what else?
        
        
        
        
        
    }
    
}

- (void)setMessageBody:(NSString *)value {
    if (messageBody != value) {
        [messageBody release];
        messageBody = [value retain];
    }
}

- (NSString*)messageBody {
    
    if (!messageBody) {
        NSUInteger usedEncoding;
        NSError *err = nil;
        
        NSString *fullMessage = [NSString stringWithContentsOfURL:messageURL usedEncoding:&usedEncoding error:&err];
        
        NSRange r = [fullMessage rangeOfString:@"\r\n\r\n"];
        
        if (r.location == NSNotFound) {
            messageBody = [fullMessage retain];
        }
        else {
            messageBody = [[fullMessage substringFromIndex:NSMaxRange(r)] retain];
        }
        
        if (!messageBody) {
            NSLog(@"err: %@", err);
        }
    }
    
    return messageBody;
}

@end
