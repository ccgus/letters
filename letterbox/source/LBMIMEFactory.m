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

#import "LBMIMEFactory.h"

#import "LetterBoxTypes.h"
#import <libetpan/libetpan.h>
#import "LBMIME_SinglePart.h"
#import "LBMIME_MessagePart.h"
#import "LBMIME_MultiPart.h"
#import "LBMIME_TextPart.h"
#import "LBMIME.h"


@implementation LBMIMEFactory
+ (LBMIME *)createMIMEWithMIMEStruct:(struct mailmime *)mime 
                          forMessage:(struct mailmessage *)message {
    if (mime == nil) {
        RaiseException(LBMIMEParseError, LBMIMEParseErrorDesc);
        return nil;
    }
    
    switch (mime->mm_type) {
        case MAILMIME_SINGLE:
            return [LBMIMEFactory createMIMESinglePartWithMIMEStruct:mime forMessage:message];
            break;
        case MAILMIME_MULTIPLE:
            return [[[LBMIME_MultiPart alloc] initWithMIMEStruct:mime forMessage:message] autorelease];
            break;
        case MAILMIME_MESSAGE:
            // this is what .mac returns.
            return [[[LBMIME_MessagePart alloc] initWithMIMEStruct:mime forMessage:message] autorelease];
            break;
    }
    return nil;
}

+ (LBMIME_SinglePart *)createMIMESinglePartWithMIMEStruct:(struct mailmime *)mime 
                                               forMessage:(struct mailmessage *)message {
    struct mailmime_type *aType = mime->mm_content_type->ct_type;
    if (aType->tp_type != MAILMIME_TYPE_DISCRETE_TYPE) {
        /* What do you do with a composite single part? */
        return nil;
    }
    LBMIME_SinglePart *content = nil;
    switch (aType->tp_data.tp_discrete_type->dt_type) {
        case MAILMIME_DISCRETE_TYPE_TEXT:
            content = [[LBMIME_TextPart alloc] initWithMIMEStruct:mime 
                                                       forMessage:message];
            break;
        default:
            content = [[LBMIME_SinglePart alloc] initWithMIMEStruct:mime 
                                                         forMessage:message];
            break;
    }
    return [content autorelease];
}
@end 
