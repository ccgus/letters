//
//  MailUtils.h
//  YourMove
//
//  Created by Jens Alfke on 7/13/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MailOutgoingMessage;


@interface OutgoingEmail : NSObject 
{
    NSString *_subject, *_body, *_sender;
    NSMutableArray *_toRecipients, *_attachments;
    MailOutgoingMessage *_message;
}

+ (BOOL) isMailRunning;

- (id) init;
- (id) initWithSubject: (NSString*)subject body: (NSString*)body;

@property (copy) NSString *subject, *body, *sender;
@property (retain) NSMutableArray *toRecipients, *attachments;

- (void) show;
- (void) send;

@end
