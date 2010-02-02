//
//  MailUtils.m
//  YourMove
//
//  Created by Jens Alfke on 7/13/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Adapted from Apple's "SBSendEmail" sample app.
//

#import "MailUtils.h"
#import "MailBridge.h"
#import "CollectionUtils.h"


@implementation OutgoingEmail


- (id) init
{
    self = [super init];
    if (self != nil) {
        _toRecipients = [[NSMutableArray alloc] init];
        _attachments  = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) initWithSubject: (NSString*)subject body: (NSString*)body
{
    self = [self init];
    if (self != nil) {
        self.subject = subject;
        self.body = body;
    }
    return self;
}

- (void) dealloc
{
    [_message release];
    [_subject release];
    [_body release];
    [_sender release];
    [_toRecipients release];
    [_attachments release];
    [super dealloc];
}


@synthesize subject=_subject, sender=_sender, body=_body,
            toRecipients=_toRecipients, attachments=_attachments;


+ (MailApplication*) mailApp
{
    /* create a Scripting Bridge object for talking to the Mail application */
    MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    mail.timeout = 5*60; // in ticks
    return mail;
}

+ (BOOL) isMailRunning
{
    return [self mailApp].isRunning;
}

- (MailOutgoingMessage*) _message
{
    if( ! _message ) {
        MailApplication *mail = [[self class] mailApp];
        
        /* create a new outgoing message object */
        MailOutgoingMessage *emailMessage =
            [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                                                 $dict({@"subject", self.subject},
                                                                       {@"content", self.body})];
        
        /* set the sender, show the message */
        if( _sender )
            emailMessage.sender = _sender;
        
        /* Have to add this to a container now, else the scripting bridge complains */
        [[mail outgoingMessages] addObject: emailMessage];

        /* create a new recipient and add it to the recipients list */
        for( NSString *recipient in _toRecipients ) {
            MailToRecipient *theRecipient =
                [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                                                 $dict({@"address", recipient})];
            [emailMessage.toRecipients addObject: theRecipient];
        }
        
        /* add an attachment, if one was specified */
        for( NSString *attachmentPath in self.attachments ) {
            /* create an attachment object */
            MailAttachment *theAttachment = 
                [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                                                                 $dict({@"fileName", attachmentPath})];
            
            /* add it to the list of attachments */
            [[emailMessage.content attachments] addObject: theAttachment];
        }
        
        /* add the object to the mail app  */
        _message = [emailMessage retain];
    }
    return _message;
}


- (void) show
{
	self._message.visible = YES;
    [[[self class] mailApp] activate];
}


- (void) send
{
	[self._message send];
}


@end




TestCase(MailUtils) {
    OutgoingEmail *m = [[OutgoingEmail alloc] initWithSubject: @"This is a test"
                                                         body: @"Hi there! This is a test email from an automated test case. http://mooseyard.com/"];
    [m.toRecipients addObject: @"jens@mooseyard.com"];
    [m show];
    //[m send];
    [m release];
}
