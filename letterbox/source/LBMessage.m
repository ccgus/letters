//
//  LBMessage.m
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBMessage.h"

@implementation LBMessage

@synthesize uuid;
@synthesize messageId;
@synthesize messageURL;
@synthesize subject;
@synthesize sender;
@synthesize to;

- (id)initWithURL:(NSURL*)fileURL {
	self = [super init];
	if (self != nil) {
		self.messageURL = fileURL;
	}
    
	return self;
}

- (void)dealloc {
    
    [uuid release];
    [messageId release];
    [messageURL release];
    [messageBody release];
    [subject release];
    [sender release];
    [to release];
    
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
        messageBody = [[NSString stringWithContentsOfURL:messageURL usedEncoding:&usedEncoding error:&err] retain];
        
        if (!messageBody) {
            NSLog(@"err: %@", err);
        }
    }
    
    return messageBody;
}

@end
