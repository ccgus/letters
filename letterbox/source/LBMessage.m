//
//  LBMessage.m
//  LetterBox
//
//  Created by August Mueller on 1/30/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBMessage.h"
#import "LetterBoxUtilities.h"
#import "LBMIMEParser.h"

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
@synthesize mimePart;
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
    LBRelease(mimePart);
    
    [super dealloc];
}


- (id)copyWithZone:(NSZone*)zone {
    
    LBMessage *m    = [[[self class] alloc] init];
    
    m->localUUID    = [[self localUUID] copy];
    m->serverUID    = [[self serverUID] copy];
    m->messageId    = [[self messageId] copy];
    m->inReplyTo    = [[self inReplyTo] copy];
    m->mailbox      = [[self mailbox] copy];
    m->subject      = [[self subject] copy];
    m->sender       = [[self sender] copy];
    m->to           = [[self to] copy];
    m->messageBody  = [[self messageBody] copy];
    m->messageURL   = [[self messageURL] copy];
    m->receivedDate = [[self receivedDate] copy];
    m->sendDate     = [[self sendDate] copy];
    m->flags        = [[self flags] copy];
    
    return m;
}

- (id) copy {
    return [self copyWithZone:nil];
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
        
        if (fullMessage == nil) {
            if ([[err domain] isEqual:NSCocoaErrorDomain] && [err code] == 264 /*unknown encoding*/ ) {
                fullMessage = [NSString stringWithContentsOfURL:messageURL encoding:NSMacOSRomanStringEncoding error:&err];
            }
        }
        
        if (fullMessage == nil) {
            fullMessage = [err localizedDescription];
        }
        
        debug( @"URL: %@", messageURL );
        
        mimePart = [LBMIMEParser messageFromString:fullMessage];
        debug( @"%@", [mimePart contentType] );
        for (LBMIMEMessage *part in mimePart.subparts) {
            NSLog(@"sub part: %@", [part contentType]);
        }
        
        NSRange r = [fullMessage rangeOfString:@"\r\n\r\n"];
        
        if (r.location == NSNotFound) {
            messageBody = [fullMessage retain];
        }
        else {
            LBMIMEMessage *representation = [mimePart availablePartForTypeFromArray:[NSArray arrayWithObjects: @"text/plain", @"text/html", nil]];
            
            messageBody = [representation.content copy];
            
            //messageBody = [[fullMessage substringFromIndex:NSMaxRange(r)] retain];
        }
        
        if (!messageBody) {
            NSLog(@"err: %@", err);
        }
    }
    
    return messageBody;
}

@end
