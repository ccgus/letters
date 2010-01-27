/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRELB, INDIRELB, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRALB, STRILB
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "LBMessage.h"
#import "LBFolder.h"
#import "LetterBoxTypes.h"
#import "LBAddress.h"
#import "LBMIMEFactory.h"
#import "LBMIME_MessagePart.h"
#import "LBMIME_TextPart.h"
#import "LBMIME_MultiPart.h"
#import "LBBareAttachment.h"

@interface LBMessage (Private)
- (LBAddress *)_addressFromMailbox:(struct mailimf_mailbox *)mailbox;
- (NSSet *)_addressListFromMailboxList:(struct mailimf_mailbox_list *)mailboxList;
- (struct mailimf_mailbox_list *)_mailboxListFromAddressList:(NSSet *)addresses;
- (NSSet *)_addressListFromIMFAddressList:(struct mailimf_address_list *)imfList;
- (struct mailimf_address_list *)_IMFAddressListFromAddresssList:(NSSet *)addresses;
- (void)_buildUpBodyText:(LBMIME *)mime result:(NSMutableString *)result;
- (void)_buildUpHtmlBodyText:(LBMIME *)mime result:(NSMutableString *)result;
- (NSString *)_decodeMIMEPhrase:(char *)data;
@end

//TODO Add encode of subjects/from/to
//TODO Add decode of to/from ...
/*
char * etpan_encode_mime_header(char * phrase)
{
  return
    etpan_make_quoted_printable(DEFAULT_DISPLAY_CHARSET,
        phrase);
}
*/

@implementation LBMessage
@synthesize mime=parsedMIME;
@synthesize sequenceNumber;

- (id)init {
    [super init];
    if (self) {
        struct mailimf_fields *ffields = mailimf_fields_new_empty();
        fields = mailimf_single_fields_new(ffields);
        mailimf_fields_free(ffields);
    }
    return self;
}


- (id)initWithMessageStruct:(struct mailmessage *)aMessage {
    self = [super init];
    if (self) {
        assert(aMessage != NULL);
        message = aMessage;
        fields = mailimf_single_fields_new(message->msg_fields);
    }
    return self;
}

- (id)initWithFileAtPath:(NSString *)path {
    return [self initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL]];
}

- (id)initWithString:(NSString *)msgData {
    struct mailmessage *msg = data_message_init((char *)[msgData cStringUsingEncoding:NSUTF8StringEncoding], 
                                    [msgData lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    int err;
    struct mailmime *dummyMime;
    /* mailmessage_get_bodystructure will fill the mailmessage struct for us */
    err = mailmessage_get_bodystructure(msg, &dummyMime);
    assert(err == 0);
    return [self initWithMessageStruct:msg];
}


- (void)dealloc {
    if (message != NULL) {
        mailmessage_flush(message);
        mailmessage_free(message);
    }
    if (fields != NULL) {
        mailimf_single_fields_free(fields);
    }
    
    [messageId release];
    [bodyCache release];
    [parsedMIME release];
    [super dealloc];
}


- (int)fetchBody {
    int err;
    struct mailmime *dummyMime;
    //Retrieve message mime and message field
    err = mailmessage_get_bodystructure(message, &dummyMime);
    if(err != 0) { // added by gabor
        return err;
    }
    parsedMIME = [[LBMIMEFactory createMIMEWithMIMEStruct:[self messageStruct]->msg_mime  forMessage:[self messageStruct]] retain];
    
    return 0;
}


- (NSString *)body {
    
    if (bodyCache) {
        return bodyCache;
    }
    
    if (!parsedMIME) {
        [self fetchBody];
    }
    
    NSMutableString *result = [NSMutableString string];
    [self _buildUpBodyText:parsedMIME result:result];
    
    bodyCache = [result copy];
    
    return bodyCache;
}

- (NSString *)htmlBody {
    // added by Gabor
    NSMutableString *result = [NSMutableString string];
    [self _buildUpHtmlBodyText:parsedMIME result:result];
    return result;
}


- (void)_buildUpBodyText:(LBMIME *)mime result:(NSMutableString *)result {
    
    if (mime == nil) {
        return;
    }
    
    if ([mime isKindOfClass:[LBMIME_MessagePart class]]) {
        [self _buildUpBodyText:[mime content] result:result];
    }
    else if ([mime isKindOfClass:[LBMIME_TextPart class]]) {
        if ([mime.contentType isEqualToString:@"text/plain"]) {
            [(LBMIME_TextPart *)mime fetchPart];
            NSString* y = [mime content];
            if(y != nil) {
                [result appendString:y];
            }
        }
    }
    else if ([mime isKindOfClass:[LBMIME_MultiPart class]]) {
        //TODO need to take into account the different kinds of multipart
        NSEnumerator *enumer = [[mime content] objectEnumerator];
        LBMIME *subpart;
        while ((subpart = [enumer nextObject])) {
            [self _buildUpBodyText:subpart result:result];
        }
    }
}

- (void)_buildUpHtmlBodyText:(LBMIME *)mime result:(NSMutableString *)result {
    if (mime == nil) {
        return;
    }
    
    if ([mime isKindOfClass:[LBMIME_MessagePart class]]) {
        [self _buildUpHtmlBodyText:[mime content] result:result];
    }
    else if ([mime isKindOfClass:[LBMIME_TextPart class]]) {
        if ([mime.contentType isEqualToString:@"text/html"]) {
            [(LBMIME_TextPart *)mime fetchPart];
            NSString* y = [mime content];
            if(y != nil) {
                [result appendString:y];
            }
        }
    }
    else if ([mime isKindOfClass:[LBMIME_MultiPart class]]) {
        //TODO need to take into account the different kinds of multipart
        NSEnumerator *enumer = [[mime content] objectEnumerator];
        LBMIME *subpart;
        while ((subpart = [enumer nextObject])) {
            [self _buildUpHtmlBodyText:subpart result:result];
        }
    }
}


- (void)setBody:(NSString *)body {
    LBMIME *oldMIME = parsedMIME;
    LBMIME_TextPart *text = [LBMIME_TextPart mimeTextPartWithString:body];
    LBMIME_MessagePart *messagePart = [LBMIME_MessagePart mimeMessagePartWithContent:text];
    parsedMIME = [messagePart retain];
    [oldMIME release];
}

- (NSArray *)attachments {
    NSMutableArray *attachments = [NSMutableArray array];

    LBMIME_Enumerator *enumerator = [parsedMIME mimeEnumerator];
    LBMIME *mime;
    while ((mime = [enumerator nextObject])) {
        if ([mime isKindOfClass:[LBMIME_SinglePart class]]) {
            LBMIME_SinglePart *singlePart = (LBMIME_SinglePart *)mime;
            if (singlePart.attached) {
                LBBareAttachment *attach = [[LBBareAttachment alloc] 
                                                initWithMIMESinglePart:singlePart];
                [attachments addObject:attach];
                [attach release];
            }
        }
    }
    return attachments;
}

- (void)addAttachment:(LBAttachment *)attachment {
}


- (NSString *)subject {
    if (fields->fld_subject == NULL) {
        return @"";
    }
        
    NSString *decodedSubject = [self _decodeMIMEPhrase:fields->fld_subject->sbj_value];
    if (decodedSubject == nil) {
        return @"";
    }
    
    return decodedSubject;
}


- (void)setSubject:(NSString *)subject {
    struct mailimf_subject *subjectStruct;
    
    subjectStruct = mailimf_subject_new(strdup([subject cStringUsingEncoding:NSUTF8StringEncoding]));
    if (fields->fld_subject != NULL) {
        mailimf_subject_free(fields->fld_subject);
    }
    
    fields->fld_subject = subjectStruct;
}


//- (NSCalendarDate *)sentDate {
//      if ( _fields->fld_orig_date == NULL) {
//      return [NSDate distantPast];
//  }
//      else {
//      //This feels like a hack, there should be a better way to deal with the time zone
//      NSInteger seconds = 60*60*_fields->fld_orig_date->dt_date_time->dt_zone/100;
//      NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:seconds];
//      return [NSCalendarDate dateWithYear:_fields->fld_orig_date->dt_date_time->dt_year 
//                                      month:_fields->fld_orig_date->dt_date_time->dt_month
//                                        day:_fields->fld_orig_date->dt_date_time->dt_day
//                                       hour:_fields->fld_orig_date->dt_date_time->dt_hour
//                                     minute:_fields->fld_orig_date->dt_date_time->dt_min
//                                    second:_fields->fld_orig_date->dt_date_time->dt_sec
//                                   timeZone:timeZone];
//      }
//}


- (BOOL)isNew {
    struct mail_flags *flags = message->msg_flags;
    if (flags != NULL) {
        if ( ((flags->fl_flags & MAIL_FLAG_SEEN) == 0) && ((flags->fl_flags & MAIL_FLAG_NEW) == 0)) {
            return YES;
        }
            
    }
    return NO;
}


- (void)setMessageId:(NSString *)value {
    if (messageId != value) {
        [messageId release];
        messageId = [value retain];
    }
}



- (NSString *)messageId {
    
    // this would be cached.
    if (messageId) {
        return messageId;
    }
    
    if (fields->fld_message_id != NULL) {
        char *value = fields->fld_message_id->mid_value;
        self.messageId = [NSString stringWithCString:value encoding:NSUTF8StringEncoding];
    }
    
    return messageId;
}

- (NSString *)uid {
    return [NSString stringWithCString:message->msg_uid encoding:NSUTF8StringEncoding];
}


- (NSSet *)from {
    if (fields->fld_from == NULL) {
        return [NSSet set]; //Return just an empty set
    }
        

    return [self _addressListFromMailboxList:fields->fld_from->frm_mb_list];
}


- (void)setFrom:(NSSet *)addresses {
    struct mailimf_mailbox_list *imf = [self _mailboxListFromAddressList:addresses];
    if (fields->fld_from != NULL) {
        mailimf_from_free(fields->fld_from);
    }
        
    fields->fld_from = mailimf_from_new(imf);  
}


- (LBAddress *)sender {
    if (fields->fld_sender == NULL) {
        return [LBAddress address];
    }
    
    return [self _addressFromMailbox:fields->fld_sender->snd_mb];
}

- (void) setSender:(LBAddress *)sender {
    // uh...
    // FIXME!
}

- (NSSet *)to {
    if (fields->fld_to == NULL) {
        return [NSSet set];
    }
    else {
        return [self _addressListFromIMFAddressList:fields->fld_to->to_addr_list];
    }
}


- (void)setTo:(NSSet *)addresses {
    struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];
    
    if (fields->fld_to != NULL) {
        mailimf_address_list_free(fields->fld_to->to_addr_list);
        fields->fld_to->to_addr_list = imf;
    }
    else {
        fields->fld_to = mailimf_to_new(imf);
    }
        
}


- (NSSet *)cc {
    if (fields->fld_cc == NULL) {
        return [NSSet set];
    }
    else {
        return [self _addressListFromIMFAddressList:fields->fld_cc->cc_addr_list];
    }
}


- (void)setCc:(NSSet *)addresses {
    struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];
    if (fields->fld_cc != NULL) {
        mailimf_address_list_free(fields->fld_cc->cc_addr_list);
        fields->fld_cc->cc_addr_list = imf;
    }
    else {
        fields->fld_cc = mailimf_cc_new(imf);
    }
}


- (NSSet *)bcc {
    if (fields->fld_bcc == NULL) {
        return [NSSet set];
    }
    else {
        return [self _addressListFromIMFAddressList:fields->fld_bcc->bcc_addr_list];
    }
}


- (void)setBcc:(NSSet *)addresses {
    struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];
    if (fields->fld_bcc != NULL) {
        mailimf_address_list_free(fields->fld_bcc->bcc_addr_list);
        fields->fld_bcc->bcc_addr_list = imf;
    }
    else {
        fields->fld_bcc = mailimf_bcc_new(imf);
    }
}


- (NSSet *)replyTo {
    if (fields->fld_reply_to == NULL) {
        return [NSSet set];
    }
    else {
        return [self _addressListFromIMFAddressList:fields->fld_reply_to->rt_addr_list];
    }
}


- (void)setReplyTo:(NSSet *)addresses {
    struct mailimf_address_list *imf = [self _IMFAddressListFromAddresssList:addresses];
    if (fields->fld_reply_to != NULL) {
        mailimf_address_list_free(fields->fld_reply_to->rt_addr_list);
        fields->fld_reply_to->rt_addr_list = imf;
    }
    else {
        fields->fld_reply_to = mailimf_reply_to_new(imf);
    }
}


- (NSString *)render {
    if ([parsedMIME isMemberOfClass:[parsedMIME class]]) {
        /* It's a message part, so let's set it's fields */
        struct mailimf_fields *ffields;
        struct mailimf_mailbox *sender = (fields->fld_sender != NULL) ? (fields->fld_sender->snd_mb) : NULL;
        struct mailimf_mailbox_list *from = (fields->fld_from != NULL) ? (fields->fld_from->frm_mb_list) : NULL;
        struct mailimf_address_list *replyTo = (fields->fld_reply_to != NULL) ? (fields->fld_reply_to->rt_addr_list) : NULL;
        struct mailimf_address_list *to = (fields->fld_to != NULL) ? (fields->fld_to->to_addr_list) : NULL;
        struct mailimf_address_list *cc = (fields->fld_cc != NULL) ? (fields->fld_cc->cc_addr_list) : NULL;
        struct mailimf_address_list *bcc = (fields->fld_bcc != NULL) ? (fields->fld_bcc->bcc_addr_list) : NULL;
        clist *inReplyTo = (fields->fld_in_reply_to != NULL) ? (fields->fld_in_reply_to->mid_list) : NULL;
        clist *references = (fields->fld_references != NULL) ? (fields->fld_references->mid_list) : NULL;
        char *subject = (fields->fld_subject != NULL) ? (fields->fld_subject->sbj_value) : NULL;
        
        //TODO: uh oh, when this get freed it frees stuff in the LBMessage
        //TODO: Need to make sure that fields gets freed somewhere
        ffields = mailimf_fields_new_with_data(from, sender, replyTo, to, cc, bcc, inReplyTo, references, subject);
        [(LBMIME_MessagePart *)parsedMIME setIMFFields:ffields];
    }
    
    return [parsedMIME render];
}


- (struct mailmessage *)messageStruct {
    return message;
}

/*********************************** myprivates ***********************************/
- (LBAddress *)_addressFromMailbox:(struct mailimf_mailbox *)mailbox; {
    LBAddress *address = [LBAddress address];
    if (mailbox == NULL) {
        return address;
    }
    if (mailbox->mb_display_name != NULL) {
        NSString *decodedName = [self _decodeMIMEPhrase:mailbox->mb_display_name];
        if (decodedName == nil) {
            decodedName = @"";
        }
        [address setName:decodedName];
    }
    if (mailbox->mb_addr_spec != NULL) {
        [address setEmail:[NSString stringWithCString:mailbox->mb_addr_spec encoding:NSUTF8StringEncoding]];
    }
    return address;
}


- (NSSet *)_addressListFromMailboxList:(struct mailimf_mailbox_list *)mailboxList; {
    clist *list;
    clistiter * iter;
    struct mailimf_mailbox *address;
    NSMutableSet *addressSet = [NSMutableSet set];
    
    if (mailboxList == NULL) {
        return addressSet;
    }
    
    list = mailboxList->mb_list;
    for(iter = clist_begin(list); iter != NULL; iter = clist_next(iter)) {
        address = clist_content(iter);
        [addressSet addObject:[self _addressFromMailbox:address]];
    }
    
    return addressSet;
}


- (struct mailimf_mailbox_list *)_mailboxListFromAddressList:(NSSet *)addresses {
    struct mailimf_mailbox_list *imfList = mailimf_mailbox_list_new_empty();
    NSEnumerator *objEnum = [addresses objectEnumerator];
    LBAddress *address;
    int err;
    const char *addressName;
    const char *addressEmail;

    while(address = [objEnum nextObject]) {
        addressName = [[address name] cStringUsingEncoding:NSUTF8StringEncoding];
        addressEmail = [[address email] cStringUsingEncoding:NSUTF8StringEncoding];
        err =  mailimf_mailbox_list_add_mb(imfList, strdup(addressName), strdup(addressEmail));
        assert(err == 0);
    }
    return imfList; 
}


- (NSSet *)_addressListFromIMFAddressList:(struct mailimf_address_list *)imfList {
    clist *list;
    clistiter * iter;
    struct mailimf_address *address;
    NSMutableSet *addressSet = [NSMutableSet set];
    
    if (imfList == NULL) {
        return addressSet;
    }
    
    list = imfList->ad_list;
    for(iter = clist_begin(list); iter != NULL; iter = clist_next(iter)) {
        address = clist_content(iter);
        /* Check to see if it's a solo address a group */
        if (address->ad_type == MAILIMF_ADDRESS_MAILBOX) {
            [addressSet addObject:[self _addressFromMailbox:address->ad_data.ad_mailbox]];
        }
        else {
            if (address->ad_data.ad_group->grp_mb_list != NULL) {
                [addressSet unionSet:[self _addressListFromMailboxList:address->ad_data.ad_group->grp_mb_list]];
            }
        }
    }
    return addressSet;
}


- (struct mailimf_address_list *)_IMFAddressListFromAddresssList:(NSSet *)addresses {
    struct mailimf_address_list *imfList = mailimf_address_list_new_empty();
    
    NSEnumerator *objEnum = [addresses objectEnumerator];
    LBAddress *address;
    int err;
    const char *addressName;
    const char *addressEmail;

    while(address = [objEnum nextObject]) {
        addressName = [[address name] cStringUsingEncoding:NSUTF8StringEncoding];
        addressEmail = [[address email] cStringUsingEncoding:NSUTF8StringEncoding];
        err =  mailimf_address_list_add_mb(imfList, strdup(addressName), strdup(addressEmail));
        assert(err == 0);
    }
    return imfList;
}

- (NSString *)_decodeMIMEPhrase:(char *)data {
    int err;
    size_t currToken = 0;
    char *decodedSubject;
    NSString *result;
    
    if (*data != '\0') {
        err = mailmime_encoded_phrase_parse(DEST_CHARSET, data, strlen(data),
            &currToken, DEST_CHARSET, &decodedSubject);
            
        if (err != MAILIMF_NO_ERROR) {
            if (decodedSubject == NULL) {
                free(decodedSubject);
            }
            
            return nil;
        }
    }
    else {
        return @"";
    }
        
    result = [NSString stringWithCString:decodedSubject encoding:NSUTF8StringEncoding];
    free(decodedSubject);
    return result;
}

NSString *LBMessageToPropertKey             = @"toAddress";
NSString *LBMessageFromPropertKey           = @"fromAddress";
NSString *LBMessageSenderPropertKey         = @"senderAddress";
NSString *LBMessageSubjectPropertKey        = @"subject";
NSString *LBMessageMessageIDPropertKey      = @"messageid";
NSString *LBMessageRecievedDatePropertKey   = @"receivedDate";
NSString *LBMessageSendDatePropertKey       = @"sendDate";
NSString *LBMessageBodyTextPropertKey       = @"bodyTextThisNeedsToGoAwayASAP";

// FIXME: use an encoder instead?

- (NSDictionary*) propertyListRepresentation {
    
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    
    NSString *firstFrom = [[[self from] anyObject] email];
    NSString *firstTo   = [[[self from] anyObject] email];
    
    [props setValue:firstFrom               forKey:LBMessageFromPropertKey];
    [props setValue:firstTo                 forKey:LBMessageToPropertKey];
    [props setValue:[self messageId]        forKey:LBMessageMessageIDPropertKey];
    
    [props setValue:[self subject]          forKey:LBMessageSubjectPropertKey];
    [props setValue:[[self sender] email]   forKey:LBMessageSenderPropertKey];
    
    // FIXME: find out the diff between sender and from
    
    
    [props setValue:[self body] forKey:LBMessageBodyTextPropertKey];
    
    return props;
}

- (void) loadPropertyListRepresentation:(NSDictionary*)propList {
    
    NSString *from = [propList objectForKey:LBMessageFromPropertKey];
    if (from) {
        [self setFrom:[NSSet setWithObject:[LBAddress addressWithName:@"" email:from]]];
    }
    
    NSString *to = [propList objectForKey:LBMessageToPropertKey];
    if (to) {
        [self setFrom:[NSSet setWithObject:[LBAddress addressWithName:@"" email:to]]];
    }
   
    messageId = [[propList objectForKey:LBMessageMessageIDPropertKey] retain];
    bodyCache = [[propList objectForKey:LBMessageBodyTextPropertKey] retain];
    
    if ([propList objectForKey:LBMessageSubjectPropertKey]) {
        [self setSubject:[propList objectForKey:LBMessageSubjectPropertKey]];
    }
    
    
}

- (void) writePropertyListRepresentationToURL:(NSURL*)fileURL {
    
    NSDictionary *propList  = [self propertyListRepresentation];
    NSError *err            = nil;
    NSString *errString     = nil;
    NSData *data            = [NSPropertyListSerialization dataFromPropertyList:propList format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errString];
    
    if (errString) {
        NSLog(@"errString: %@", errString);
        return;
    }
    
    assert(data);
    
    if (![data writeToURL:fileURL options:NSDataWritingAtomic error:&err]) {
        NSLog(@"Could not write to %@", [fileURL path]);
        NSLog(@"err: %@", err);
    }
}

- (void) loadPropertyListRepresentationFromURL:(NSURL*)fileURL {
    
    NSString *error = nil;
    NSDictionary *d = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:fileURL]
                                                       mutabilityOption:NSPropertyListImmutable
                                                                 format:nil
                                                       errorDescription:&error];
    
    if (error) {
        NSLog(@"error loading %@", fileURL);
        NSLog(@"error: %@", error);
    }
    
    assert(d);
    
    [self loadPropertyListRepresentation:d];
}

- (BOOL) messageDownloaded {
    return bodyCache != nil;
}



@end
