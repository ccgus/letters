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


#import "LBAddress.h"
#import "LetterBoxUtilities.h"

@implementation LBAddress

@synthesize email;
@synthesize name;

+ (id)address {
    LBAddress *aAddress = [[LBAddress alloc] init];
    return [aAddress autorelease];
}


+ (id)addressWithName:(NSString *)aName email:(NSString *)aEmail {
    LBAddress *aAddress = [[LBAddress alloc] initWithName:aName email:aEmail];
    return [aAddress autorelease];
}


- (id)initWithName:(NSString *)aName email:(NSString *)aEmail {
    self = [super init];
    if (self) {
        [self setName:aName];
        [self setEmail:aEmail];
    }
    return self;
}


- (id)init {
    self = [super init];
    if (self) {
        [self setName:@""];
        [self setEmail:@""];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    [self setName:[aDecoder decodeObjectForKey:@"name"]];
    [self setEmail:[aDecoder decodeObjectForKey:@"email"]];
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:email forKey:@"email"];
    [aCoder encodeObject:name forKey:@"name"];
}


- (void)dealloc {
    [email release];
    [name release];
    [super dealloc];
}

-(NSString*)decodedName {
    // added by Gabor
    // FIXME: Why not use hasPrefix: here?
    if (StringStartsWith(self.name, @"=?ISO-8859-1?Q?")) {
        NSString* newName = [self.name substringFromIndex:[@"=?ISO-8859-1?Q?" length]];
        newName = [newName stringByReplacingOccurrencesOfString:@"?=" withString:@""];
        newName = [newName stringByReplacingOccurrencesOfString:@"__" withString:@" "];
        newName = [newName stringByReplacingOccurrencesOfString:@"=" withString:@"%"];      
        newName = [newName stringByReplacingPercentEscapesUsingEncoding:NSISOLatin1StringEncoding];
        return newName;
    }
    return self.name;
}



- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[LBAddress class]]) {
        return NO;
    }
        
    return [[object name] isEqualToString:[self name]] && [[object email] isEqualToString:[self email]];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ %@ <%@>)", [super description], name, email];
}

@end
