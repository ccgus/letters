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

#import "LBBareAttachment.h"

#import "LetterBoxUtilities.h"
#import "LetterBoxTypes.h"
#import "LBMIME_SinglePart.h"
#import "LBAttachment.h"

@implementation LBBareAttachment
@synthesize contentType;
@synthesize filename;

- (id)initWithMIMESinglePart:(LBMIME_SinglePart *)part {
    self = [super init];
    if (self) {
        MIMEPart = [part retain];
        self.filename = MIMEPart.filename;
        self.contentType = MIMEPart.contentType;
    }
    return self;
}

- (void)dealloc {
    [MIMEPart release];
    [filename release];
    [contentType release];
    [super dealloc];
}

-(NSString*)decodedFilename {
    // FIXME: Why not use hasPrefix: here?
    // added by Gabor
    if (StringStartsWith(self.filename, @"=?ISO-8859-1?Q?")) {
        NSString* newName = [self.filename substringFromIndex:[@"=?ISO-8859-1?Q?" length]];
        newName = [newName stringByReplacingOccurrencesOfString:@"?=" withString:@""];
        newName = [newName stringByReplacingOccurrencesOfString:@"__" withString:@" "];
        newName = [newName stringByReplacingOccurrencesOfString:@"=" withString:@"%"];      
        newName = [newName stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
        return newName;
    }
    
    return self.filename;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"ContentType: %@\tFilename: %@",
                self.contentType, self.filename];
}

- (LBAttachment *)fetchFullAttachment {
    [MIMEPart fetchPart];
    LBAttachment *attach = [[LBAttachment alloc] initWithData:MIMEPart.data
                                                  contentType:self.contentType
                                                     filename:self.filename];
    return [attach autorelease];
}


@end
