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
 
#import "LBMIME_Enumerator.h"

#import "LBMIME.h"
#import "LBMIME_MultiPart.h"
#import "LBMIME_MessagePart.h"

@implementation LBMIME_Enumerator
- (id)initWithMIME:(LBMIME *)mime {
    self = [super init];
    if (self) {
        _toVisit = [[NSMutableArray alloc] init];
        [_toVisit addObject:mime];
    }
    return self;
}

- (void)dealloc {
    [_toVisit release];
    [super dealloc];
}

- (NSArray *)allObjects {
    NSMutableArray *objects = [NSMutableArray array];
    
    id obj;
    while ((obj = [self nextObject])) {
        [objects addObject:obj];
    }
    return objects;
}

- (id)nextObject {
    if ([_toVisit count] == 0) {
        return nil;
    }
    
    id mime = [_toVisit objectAtIndex:0];
    if ([mime isKindOfClass:[LBMIME_MessagePart class]]) {
        if ([mime content] != nil) {
            [_toVisit addObject:[mime content]];
        }
    }
    else if ([mime isKindOfClass:[LBMIME_MultiPart class]]) {
        NSEnumerator *enumer = [[mime content] objectEnumerator];
        LBMIME *subpart;
        while ((subpart = [enumer nextObject])) {
            [_toVisit addObject:subpart];
        }
    }
    
    [_toVisit removeObjectAtIndex:0];
    return mime;
}

@end
