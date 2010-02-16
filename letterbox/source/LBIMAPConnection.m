#import "LBIMAPConnection.h"
#import "LBTCPReader.h"
#import "LetterBoxUtilities.h"
#import "TCP_Internal.h"
#import "LBAccount.h"
#import "IPAddress.h"


static NSString *LBLOGIN = @"LOGIN";
static NSString *LBLSUB = @"LSUB";
static NSString *LBSELECT = @"SELECT";
static NSString *LBLOGOUT = @"LOGOUT";
static NSString *LBCREATE = @"CREATE";
static NSString *LBDELETE = @"DELETE";
static NSString *LBSUBSCRIBE = @"SUBSCRIBE";
static NSString *LBUNSUBSCRIBE = @"UNSUBSCRIBE";
static NSString *LBSEARCH = @"SEARCH";
static NSString *LBFETCH = @"FETCH";
static NSString *LBIDLE = @"IDLE";
static NSString *LBDONE = @"DONE";


@interface LBIMAPConnection ()
- (void)endIDLE;
@end

@implementation LBIMAPConnection


- (id)initWithAccount:(LBAccount*)account {
    
    IPAddress *addr = [IPAddress addressWithHostname:[account imapServer] port:[account imapPort]];
    self = [self initToAddress:addr];
    
	if (self != nil) {
            
        if ([account imapTLS]) {
            
            NSMutableDictionary *sslProps = [NSMutableDictionary dictionary];
            
            [sslProps setObject:[NSNumber numberWithBool:YES] forKey:(id)kTCPPropertySSLAllowsAnyRoot];
            [sslProps setObject:[NSNull null] forKey:(id)kCFStreamSSLPeerName];
            [sslProps setObject:NSStreamSocketSecurityLevelTLSv1 forKey:(id)kCFStreamSSLLevel];
            
            [self setSSLProperties:sslProps];
        }
    }
    
    return self;
}

- (NSString*)modifyCommandString:(NSString*)commandString {
    commandCount++;
    
    commandString = [NSString stringWithFormat:@"%d %@", commandCount, commandString];
    
    return commandString;
}


- (void)endIDLE {
    if (currentCommand == LBIDLE) {
        [self sendCommand:LBDONE withArgument:nil];
    }
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password block:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBLOGIN withArgument:[NSString stringWithFormat:@"%@ %@", username, password]];
}

- (void)selectMailbox:(NSString*)mailbox block:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBSELECT withArgument:mailbox];
}

- (void)listMessagesWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBSEARCH withArgument:@"ALL"];
}

- (void)listSubscribedMailboxesWithBock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBLSUB withArgument:@"\"\" \"*\""];
}

- (void)idleWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBIDLE withArgument:nil];
}

- (void)logoutWithBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    [self sendCommand:LBLOGOUT withArgument:nil];
}


- (void)createMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    [self sendCommand:LBCREATE withArgument:mailboxName];
}

- (void)deleteMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    [self sendCommand:LBDELETE withArgument:mailboxName];
}


- (void)subscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    [self sendCommand:LBSUBSCRIBE withArgument:mailboxName];
}

- (void)unsubscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    [self sendCommand:LBUNSUBSCRIBE withArgument:mailboxName];
}

- (void)fetchMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block; {
    responseBlock = [block copy];
    
    NSString *format = [NSString stringWithFormat:@"%@ (RFC822)", seqIds];
    
    [self sendCommand:LBFETCH withArgument:format];
}

- (NSDictionary *)parseLSUBLine:(NSString*)line {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    // SANITY
    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    /*
   Example:    C: A002 LSUB "#news." "comp.mail.*"
               S: * LSUB () "." #news.comp.mail.mime
               S: * LSUB () "." #news.comp.mail.misc
               S: A002 OK LSUB completed
               C: A003 LSUB "#news." "comp.%"
               S: * LSUB (\NoSelect) "." #news.comp.mail
               S: A003 OK LSUB completed
    
    
     
     * LSUB (\HasNoChildren) "." "INBOX.Sent"
     * LSUB (\Noselect \HasChildren) "." "INBOX.Drafts"
     
    
     */
     
    
    [d setObject:line forKey:@"raw"];
    
    if (![line hasPrefix:@"* LSUB "]) {
        return nil;
    }
    
    NSString *nextBit = [line substringFromIndex:7];
    
    NSRange parenStart = [nextBit rangeOfString:@"("];
    NSRange parenEnd   = [nextBit rangeOfString:@")"];
    
    if (parenStart.location == NSNotFound || parenEnd.location == NSNotFound) {
        return nil;
    }
    
    NSString *flags = [nextBit substringWithRange:NSMakeRange(parenStart.location + 1, parenEnd.location - 1)];
    NSMutableArray *flagsArray = [NSMutableArray array];
    
    for (NSString *flag in [flags componentsSeparatedByString:@"\\"]) {
        flag = [flag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([flag length]) {
            [flagsArray addObject:flag];
        }
    }
    
    [d setObject:flagsArray forKey:@"flags"];
    
    nextBit = [nextBit substringFromIndex:NSMaxRange(parenEnd)];
    
    // next up, we have the path separator, in quotes
    // there's also some whitespace at the front, but we'll just ignore it for now.
    
    NSRange quoteStart = [nextBit rangeOfString:@"\""];
    
    if (quoteStart.location == NSNotFound) {
        // akk!
        debug(@"no start to the quote");
        return nil;
    }
    
    NSRange leftOver   = NSMakeRange(NSMaxRange(quoteStart) + 1, [nextBit length] - (NSMaxRange(quoteStart) + 1));
    NSRange quoteEnd   = [nextBit rangeOfString:@"\"" options:0 range:leftOver];
    
    if (quoteEnd.location == NSNotFound) {
        // akk!
        debug(@"no end to the quote!");
        return nil;
    }
    
    NSString *pathDelim = [nextBit substringWithRange:NSMakeRange(NSMaxRange(quoteStart), quoteEnd.location - 2)];
    
    [d setObject:pathDelim forKey:@"hierarchyDelimiter"];
    
    if (!([nextBit length] > NSMaxRange(quoteEnd) + 1)) {
        return nil; // no mailbox name?  wtf?
    }
    
    nextBit = [[nextBit substringFromIndex:NSMaxRange(quoteEnd) + 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!([nextBit hasPrefix:@"\""] && [nextBit hasSuffix:@"\""])) {
        return nil; // not a good name.
    }
    
    NSString *name = [nextBit substringWithRange:NSMakeRange(1, [nextBit length] - 2)];
    
    [d setObject:name forKey:@"mailboxName"];
    
    return d;
}

- (NSArray*)fetchedMailboxes {
    if (currentCommand != LBLSUB) {
        NSLog(@"Error: you need to do a list command first!");
        return nil;
    }
    
    NSMutableArray *ret = [NSMutableArray array];
    NSString *theList   = [self responseAsString];
    
    for (NSString *line in [theList componentsSeparatedByString:@"\r\n"]) {
        
        if ([line hasPrefix:@"* LSUB ("]) {
            
            NSDictionary *mboxInfo = [self parseLSUBLine:line];
            
            if (mboxInfo) {
                [ret addObject:mboxInfo];
            }
            else {
                NSLog(@"Could not parse list command: %@", line);
            }
        }
        else {
            // eh? wtf?  Ok, I know the last line is num + OK, but what else could there be?
        }
    }
    
    return ret;
    
}

- (NSArray*)searchedResultSet {
    if (currentCommand != LBSEARCH) {
        NSLog(@"Error: you need to do a SEARCH command first!");
        return nil;
    }
    
    NSString *list = [self responseAsString];
    
    if (![list hasPrefix:@"* SEARCH"]) {
        NSLog(@"Error: bad search result:");
        NSLog(@"%@", list);
        return nil;
    }
    
    // eek, it's empty!
    if (![list hasPrefix:@"* SEARCH "]) {
        return [NSArray array];
    }
    
    list = [list substringFromIndex:9];
    
    NSString *lastLine = [self lastLineOfData:self.responseBytes];
    
    // now, let's cut that last bit out.
    // the -4 is for the 2 crlf's in there.
    list = [list substringToIndex:[list length] - [lastLine length] - 4];
    
    return [list componentsSeparatedByString:@" "];
}


- (NSData*)lastFetchedMessage {
    if (currentCommand != LBFETCH) {
        NSLog(@"Error: you need to do a fetch command first!");
        return nil;
    }
    
    // 1486
    NSInteger headerLen = [currentFetchingMessageHeader length] + 2; // + 2 for crlf.
    
    if ([self.responseBytes length] < (headerLen + currentFetchingMessageSize)) {
        NSLog(@"There isn't enough data for the last message.  Are you calling too soon?");
        return nil;
    }
    
    NSData *data = [self.responseBytes subdataWithRange:NSMakeRange(headerLen, currentFetchingMessageSize)];
    
    return data;
}

- (void)canRead:(LBTCPReader*)reader {
    
    // what's a good number here?
    #define MAX_BYTES_READ 2048
    
    NSMutableData *data         = [NSMutableData dataWithLength:MAX_BYTES_READ];
    NSInteger localBytesRead    = [reader read:[data mutableBytes] maxLength:MAX_BYTES_READ];
    
    [self.responseBytes appendBytes:[data mutableBytes] length:localBytesRead];
    
    bytesRead += localBytesRead;
    
    if (self.debugOutput) {
        NSString *junk = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"> %@", junk);
    }
    
    if (currentCommand == LBCONNECTING) {
        
        NSString *res = [self singleLineResponseFromData:self.responseBytes];
        
        if (!res) {
            debug(@"slow connection?");
            return;
        }
        
        [self callBlockWithError:nil];
        
    }
    else if (currentCommand == LBLOGIN) {
        
        NSString *res = [self singleLineResponseFromData:self.responseBytes];
        
        if (!res) {
            debug(@"slow auth?");
            return;
        }
        
        NSString *expected = [NSString stringWithFormat:@"%d OK LOGIN", commandCount];
        
        BOOL worked = [res hasPrefix:expected];
        
        NSError *err = nil;
        
        if (!worked) {
            LBQuickError(&err, LBLOGIN, 0, @"Could not login");
        }
        
        [self callBlockWithError:err];
    }
    else if (currentCommand == LBCREATE || currentCommand == LBDELETE || currentCommand == LBSUBSCRIBE || currentCommand == LBUNSUBSCRIBE) {
        
        NSString *res = [self singleLineResponseFromData:self.responseBytes];
        
        if (!res) {
            return;
        }
        
        NSString *expected = [NSString stringWithFormat:@"%d OK ", commandCount];
        
        BOOL worked = [res hasPrefix:expected];
        
        NSError *err = nil;
        
        if (!worked) {
            // FIXME: pick up on the name of the mailbox here.
            NSString *junk = [NSString stringWithFormat:@"Error for %@: '%@'", currentCommand, expected];
            LBQuickError(&err, LBLOGIN, 0, junk);
        }
        
        [self callBlockWithError:err];
    }
    else if (currentCommand == LBLSUB) {
        
        NSString *expected = [NSString stringWithFormat:@"%d OK", commandCount];
        
        NSString *lastLine = [self lastLineOfData:self.responseBytes];
        
        if ([lastLine hasPrefix:expected]) {
            debug(@"yay?");
            // FIXME: check for correctness
            [self callBlockWithError:nil];
        }
    }
    else if (currentCommand == LBSEARCH) {
        
        NSString *expected      = [NSString stringWithFormat:@"%d OK", commandCount];
        NSString *expectedErr   = [NSString stringWithFormat:@"%d NO", commandCount];
        NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD", commandCount];
        NSString *lastLine      = [self lastLineOfData:self.responseBytes];
        
        if ([lastLine hasPrefix:expected]) {
            
            // FIXME: check for correctness
            [self callBlockWithError:nil];
        }
        else if ([lastLine hasPrefix:expectedErr] || [lastLine hasPrefix:expectedBad]) {
            
            
            
            NSError *err    = nil;
            NSString *junk  = [NSString stringWithFormat:@"Could not search mailbox: %@", [self responseAsString]];
            
            LBQuickError(&err, LBSELECT, 0, junk);
            
            [self callBlockWithError:err];
        }
        
        
    }
    else if (currentCommand == LBSELECT) {
        
        // the "[READ-WRITE]" bit is a "should" in the RFC.  Do we have any examples otherwise?
        NSString *expected = [NSString stringWithFormat:@"%d OK [READ-WRITE] Ok%s", commandCount, CRLF];
        NSString *expected2 = [NSString stringWithFormat:@"%d OK %s", commandCount, CRLF];
        
        NSError *err = nil;
        
        if (!([self endOfData:self.responseBytes isEqualTo:expected] || [self endOfData:self.responseBytes isEqualTo:expected2])) {
            NSString *junk = [NSString stringWithFormat:@"Could not Select mailbox: %@", [self responseAsString]];
            LBQuickError(&err, LBSELECT, 0, junk);
        }

        [self callBlockWithError:err];
    }
    
    else if (currentCommand == LBLOGOUT) {
        
        NSString *lastLine      = [self lastLineOfData:self.responseBytes];
        NSString *expectedGood  = [NSString stringWithFormat:@"%d OK ", commandCount, CRLF];
        NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD ", commandCount, CRLF];
        NSString *expectedErr   = [NSString stringWithFormat:@"%d NO ", commandCount, CRLF];
        
        if (!([lastLine hasPrefix:expectedGood] || [lastLine hasPrefix:expectedBad] || [lastLine hasPrefix:expectedErr])) {
            return; // we're not done reading yet.  MAYBE
        }
        
        BOOL worked = [lastLine hasPrefix:expectedGood];
        
        NSError *err = nil;
        
        if (!worked) {
            
            NSString *junk = [NSString stringWithFormat:@"Could not Logout: %@", [self responseAsString]];
            LBQuickError(&err, LBLOGOUT, 0, junk);
        }
        
        [self callBlockWithError:err];
    }
    else if (currentCommand == LBFETCH) {
        NSString *firstLine = [self firstLineOfData:self.responseBytes];
        
        if (firstLine) {
            
            // * 1 FETCH (RFC822 {2668}'
            
            // FIXME: need to be a bit more precise here.
            
            NSRange startBracket = [firstLine rangeOfString:@"{"];
            NSRange endBracket   = [firstLine rangeOfString:@"}"];
            
            if (startBracket.location == NSNotFound || endBracket.location == NSNotFound) {
                debug(@"SOMETHING BAD IS HAPPENING");
                assert(false);
            }
            
            assert(NSMaxRange(startBracket) < endBracket.location);
            
            NSString *len = [firstLine substringWithRange:NSMakeRange(NSMaxRange(startBracket), endBracket.location - NSMaxRange(startBracket))];
            
            currentFetchingMessageSize      = [len integerValue];
            
            currentFetchingMessageHeader    = [firstLine retain];
            
            // do we have our header, message, crlf, ), crlf, and an OK FETCH + something + CRLF?
            
            // yes, endMessageLength isn't accurate, but it just needs to be at least this.
            NSInteger endMessageLength = [@"\r\n)\r\n1 OK FETCH\r\n" length];
            NSInteger atLeastLength    = [currentFetchingMessageHeader length] + currentFetchingMessageSize + endMessageLength;
            
            if ([self.responseBytes length] > atLeastLength) {
                
                NSString *lastLine      = [self lastLineOfData:self.responseBytes];
                NSString *expectedGood  = [NSString stringWithFormat:@"%d OK FETCH", commandCount, CRLF];
                //NSString *expectedNo    = [NSString stringWithFormat:@"%d NO", commandCount, CRLF];
                //NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD", commandCount, CRLF];
                
                NSError *err = nil;
                
                if ([lastLine hasPrefix:expectedGood]) {
                    
                    [self callBlockWithError:err];
                }
                
            }
            
                // 10 OK FETCH completed.
            
            
            // * 1 FETCH (RFC822 {2668} crlf + 2668 bytes of data + crlf + ) + crlf + 10 OK FETCH completed.
            
        }
    }
}









@end

