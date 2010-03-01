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

#import "LetterBoxUtilities.h"
#import "LBAddress.h"
#import "JRLog.h"
#import "LBEnvelopeTokenizer.h"
#import "TDToken.h"
#import "TDWhitespaceState.h"
#import "TDCommentState.h"
#import "LBNSStringAdditions.h"

/* direction is 1 for send, 0 for receive, -1 when it does not apply */
void letterbox_logger(int direction, const char * str, size_t size) {
    char *str2 = malloc(size+1);
    strncpy(str2,str,size);
    str2[size] = 0;
    id self = nil; // Work around for using JRLogInfo in a C function
    if (direction == 1) {
        JRLogInfo(@"Client: %s\n", str2);
    }
    else if (direction == 0) {
        JRLogInfo(@"Server: %s\n", str2);
    }
    else {
        JRLogInfo(@"%s\n", str2);
    }
    free(str2);
}


void LBQuickError(NSError **err, NSString *domain, NSInteger code, NSString *description) {
    // fixme: add a com.lettersapp in front of the domain?
    if (err) {
        *err = [NSError errorWithDomain:domain code:code userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
    }
    
}



NSString *LBQuote(NSString *body, NSString *prefix) {
    NSMutableString *ret = [NSMutableString string];
    
    // normalize the line endings to make things easier.
    body = [body stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    for (NSString *line in [body componentsSeparatedByString:@"\n"]) {
        [ret appendFormat:@"%@%@\n", prefix, line];
    }
    return ret;
}


NSString *LBWrapLines(NSString *body, int width) {
    
    if (width < 10) {
        width = 10; // some sanity here please.
    }
    
    NSMutableString *ret = [NSMutableString string];
    
    
    body = [body stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    body = [body stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    for (NSString *line in [body componentsSeparatedByString:@"\n"]) {
        
        if (![line length]) {
            [ret appendString:@"\n"];
            continue;
        }
        
        int idx = 0;
        
        while ((idx < [line length]) && ([line characterAtIndex:idx] == '>')) {
            idx++;
        }
        
        NSMutableString *pre = [NSMutableString string];
        
        for (int i = 0; i < idx; i++) {
            [pre appendString:@">"];
        }
        
        NSString *oldLine = [line substringFromIndex:idx];
        
        NSMutableString *newLine = [NSMutableString string];
        
        [newLine appendString:pre];
        
        for (NSString *word in [oldLine componentsSeparatedByString:@" "]) {
            
            if ([newLine length] + [word length] > width) {
                [ret appendString:newLine];
                [ret appendString:@"\n"];
                [newLine setString:pre];
            }
            
            if ([word length] && [newLine length]) {
                [newLine appendString:@" "];
            }
            
            [newLine appendString:word];
            
        }
        
        [ret appendString:newLine];
        [ret appendString:@"\n"];
        
    }
    
    return ret;
}


NSDictionary* LBSimpleMesageHeaderSliceAndDice(NSData *msgData) {
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    
    NSUInteger len          = [msgData length];
    NSUInteger idx          = 0;
    char *cdata             = (char *)[msgData bytes];
    NSUInteger lineStart    = 0;
    
    while (idx < len - 2) {
        
        if (cdata[idx] == '\r' && cdata[idx+1] == '\n') { // CRLF
            
            // get rid of the encountered lf, and the ending crlf
            NSRange r = NSMakeRange(lineStart, idx - (lineStart));
            NSData *subData = [msgData subdataWithRange:r];
            NSString *junk = [[[NSString alloc] initWithBytes:[subData bytes] length:[subData length] encoding:NSUTF8StringEncoding] autorelease];
            
            if ([junk hasPrefix:@" "] || [junk hasPrefix:@"\t"]) {
                // it's a continuation whatsname!
                // for now, we're just ignoring it.  This function all only cares about the simple stuff.
            }
            else {
                
                NSRange r = [junk rangeOfString:@":"];
                
                if (r.location == NSNotFound || ([junk length] < r.location + 2)) {
                    debug(@"Could not find marker in: '%@'", junk);
                    idx += 2;
                    continue;
                }
                
                NSString *name = [[junk substringToIndex:r.location] lowercaseString];
                NSString *res  = [junk substringFromIndex:NSMaxRange(r) + 1];
                
                NSMutableArray *l = [headers objectForKey:name];
                if (!l) {
                    l = [NSMutableArray array];
                    [headers setObject:l forKey:name];
                }
                
                [l addObject:res];
            }
            
            lineStart = idx + 2;
            
            if (cdata[idx+2] == '\r') {
                // it's an empty line, we're done!
                break;
            }
            
            idx++; // jumpity mick jump over the \r, and then the \n below
        }
        
        idx++;
    }
    
    return headers;
}

NSString* LBUUIDString(void) {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    [uuidString autorelease];
    return [uuidString lowercaseString];
}


/*
http://tools.ietf.org/html/rfc3501#section-7.4.2

    ENVELOPE
         A parenthesized list that describes the envelope structure of a
         message.  This is computed by the server by parsing the
         [RFC-2822] header into the component parts, defaulting various
         fields as necessary.

         The fields of the envelope structure are in the following
         order: date, subject, from, sender, reply-to, to, cc, bcc,
         in-reply-to, and message-id.  The date, subject, in-reply-to,
         and message-id fields are strings.  The from, sender, reply-to,
         to, cc, and bcc fields are parenthesized lists of address
         structures.

         An address structure is a parenthesized list that describes an
         electronic mail address.  The fields of an address structure
         are in the following order: personal name, [SMTP]
         at-domain-list (source route), mailbox name, and host name.

         [RFC-2822] group syntax is indicated by a special form of
         address structure in which the host name field is NIL.  If the
         mailbox name field is also NIL, this is an end of group marker
         (semi-colon in RFC 822 syntax).  If the mailbox name field is
         non-NIL, this is a start of group marker, and the mailbox name
         field holds the group name phrase.

         If the Date, Subject, In-Reply-To, and Message-ID header lines
         are absent in the [RFC-2822] header, the corresponding member
         of the envelope is NIL; if these header lines are present but
         empty the corresponding member of the envelope is the empty
         string.
         
            Note: some servers may return a NIL envelope member in the
            "present but empty" case.  Clients SHOULD treat NIL and
            empty string as identical.

            Note: [RFC-2822] requires that all messages have a valid
            Date header.  Therefore, the date member in the envelope can
            not be NIL or the empty string.

            Note: [RFC-2822] requires that the In-Reply-To and
            Message-ID headers, if present, have non-empty content.
            Therefore, the in-reply-to and message-id members in the
            envelope can not be the empty string.

         If the From, To, cc, and bcc header lines are absent in the
         [RFC-2822] header, or are present but empty, the corresponding
         member of the envelope is NIL.

         If the Sender or Reply-To lines are absent in the [RFC-2822]
         header, or are present but empty, the server sets the
         corresponding member of the envelope to be the same value as
         the from member (the client is not expected to know to do
         this).

            Note: [RFC-2822] requires that all messages have a valid
            From header.  Therefore, the from, sender, and reply-to
            members in the envelope can not be NIL.
*/



NSDictionary* LBParseSimpleFetchResponse(NSString *fetchResponse) {
    // http://tools.ietf.org/html/rfc3501#section-6.4.5
    
    // this guy has to be an untagged response, right?
    if (![fetchResponse hasPrefix:@"*"]) {
        return nil;
    }
    
    // * 1 FETCH (FLAGS (\\Seen $NotJunk NotJunk) INTERNALDATE \"29-Jan-2010 21:44:05 -0800\" RFC822.SIZE 15650 ENVELOPE (\"Wed, 27 Jan 2010 22:51:51 +0000\" \"Re: Coding Style Guidelines\" ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Gus Mueller\" NIL \"gus\" \"lettersapp.com\")) NIL NIL \"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>\" \"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>\") UID 98656
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    
    LBEnvelopeTokenizer *tokenizer  = [LBEnvelopeTokenizer tokenizerWithString:fetchResponse];
    
    //tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    while ((tok = [tokenizer nextToken]) != eof) {
        
        NSString *tokS = [tok stringValue];
        
        if ([tokS isEqualToString:@"FLAGS"]) {
            
            NSMutableString *flags = [NSMutableString string];
            // should be a '(', so we skip over that.
            [tokenizer nextToken];
            
            tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
            while (((tok = [tokenizer nextToken]) != eof) && ![[tok stringValue] isEqualToString:@")"]) {
                [flags appendString:[tok stringValue]];
            }
            tokenizer.whitespaceState.reportsWhitespaceTokens = NO;
            
            [d setObject:flags forKey:tokS];
        }
        else if ([tokS isEqualToString:@"INTERNALDATE"] || [tokS isEqualToString:@".SIZE"] || [tokS isEqualToString:@"UID"]) {
            
            NSString *val = [[tokenizer nextToken] stringValue];
            
            val = [val stringByDeletingEndQuotes];
            
            if ([tokS isEqualToString:@".SIZE"]) {
                #warning seems to be a shortcoming of the parsing kit, that we can't ge a . to be a word.  Fix?
                tokS = @"RFC822.SIZE"; // seems to be a shortcoming of the parsing kit, that we can't ge a . to be a word.
            }
            
            [d setObject:val forKey:tokS];
        }
        else if ([tokS isEqualToString:@"ENVELOPE"]) {
            
            NSArray *tokenSections = [NSArray arrayWithObjects:@"from", @"sender", @"reply-to", @"to", @"cc", @"bcc", nil];
            
            // should be the opening (
            if (![[[tokenizer nextToken] stringValue] isEqualToString:@"("]) {
                return nil;
            }
            
            // alrighty, date, then subject
            NSString *val = [[tokenizer nextToken] stringValue];
            
            if ([val hasPrefix:@"\""] && [val hasSuffix:@"\""]) {
                val = [val substringWithRange:NSMakeRange(1, [val length] - 2)];
                [d setObject:val forKey:@"date"];
            }
            
            val = [[tokenizer nextToken] stringValue];
            if ([val hasPrefix:@"\""] && [val hasSuffix:@"\""]) {
                val = [val substringWithRange:NSMakeRange(1, [val length] - 2)];
                [d setObject:val forKey:@"subject"];
            }
            
            
            // time to parse the addresses
            for (NSString *tokSect in tokenSections) {
                
                tokS = [[tokenizer nextToken] stringValue];
                
                if ([tokS isEqualToString:@"NIL"]) {
                    continue;
                }
                
                if (![tokS isEqualToString:@"("]) {
                    NSLog(@"No opening (! (got '%@')", tokS);
                    return nil;
                }
                
                NSMutableArray *addrs = [NSMutableArray array];
                
                [d setObject:addrs forKey:tokSect];
                
                while (YES) {
                    
                    if (![[[tokenizer nextToken] stringValue] isEqualToString:@"("]) {
                        break;
                    }
                    
                    NSString *personalName = [[tokenizer nextToken] stringValue];
                    NSString *sourceRoute  = [[tokenizer nextToken] stringValue];
                    NSString *mailboxName  = [[tokenizer nextToken] stringValue];
                    NSString *hostName     = [[tokenizer nextToken] stringValue];
                    [tokenizer nextToken]; // get rid of the )
                    
                    (void)sourceRoute;
                    
                    if ([personalName isEqualToString:@""] || [personalName isEqualToString:@"NIL"]) {
                        personalName = nil;
                    }
                    
                    LBAddress *addr = [LBAddress addressWithName:[personalName stringByDeletingEndQuotes]
                                                           email:[NSString stringWithFormat:@"%@@%@", [mailboxName stringByDeletingEndQuotes], [hostName stringByDeletingEndQuotes]]];
                    
                    [addrs addObject:addr];
                }
            }
            
            NSString *inReply   = [[tokenizer nextToken] stringValue];
            NSString *messageId = [[tokenizer nextToken] stringValue];
            
            [d setObject:[inReply stringByDeletingEndQuotes] forKey:@"in-reply-to"];
            [d setObject:[messageId stringByDeletingEndQuotes] forKey:@"message-id"];
            
            // finish off the )
            [tokenizer nextToken];
            
            // in-reply-to, and message-id
        }
    }
    
    return d;
}







