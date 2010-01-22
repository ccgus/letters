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


#import "LBMIME_MessagePart.h"
#import <libetpan/libetpan.h>
#import "LetterBoxTypes.h"
#import "LBMIMEFactory.h"

@interface LBMIME_MessagePart ()
- (void)setContent:(LBMIME *)value;
@end


@implementation LBMIME_MessagePart

+ (id)mimeMessagePartWithContent:(LBMIME *)mime {
    return [[[LBMIME_MessagePart alloc] initWithContent:mime] autorelease];
}

- (id)initWithMIMEStruct:(struct mailmime *)mime 
              forMessage:(struct mailmessage *)message {
    self = [super initWithMIMEStruct:mime forMessage:message];
    if (self) {
        struct mailmime *content = mime->mm_data.mm_message.mm_msg_mime;
        _content = [[LBMIMEFactory createMIMEWithMIMEStruct:content 
                                                         forMessage:message] retain];
        _fields = mime->mm_data.mm_message.mm_fields;
    }
    return self;
}

- (id)initWithContent:(LBMIME *)messageContent {
    self = [super init];
    if (self) {
        [self setContent:messageContent];
    }
    return self;
}

- (void)dealloc {
    [_content release];
    [super dealloc];
}

- (LBMIME *) content {
    return _content;
}

- (void)setContent:(LBMIME *)value {
    if (_content != value) {
        [_content release];
        _content = [value retain];
    }
}



- (struct mailmime *)buildMIMEStruct {
    struct mailmime *mime = mailmime_new_message_data([_content buildMIMEStruct]);
    mailmime_set_imf_fields(mime, _fields);
    return mime;
}

- (void)setIMFFields:(struct mailimf_fields *)imfFields {
    _fields = imfFields;
}
@end
