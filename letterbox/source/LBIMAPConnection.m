#import "LBIMAPConnection.h"
#import "LBTCPReader.h"
#import "LetterBoxUtilities.h"
#import "TCP_Internal.h"
#import "LBAccount.h"
#import "IPAddress.h"
#import "LBMessage.h"


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
static NSString *LBSTORE = @"STORE";
static NSString *LBIDLE = @"IDLE";
static NSString *LBEXPUNGE = @"EXPUNGE";
static NSString *LBDONE = @"DONE";
static NSString *LBCAPABILITY = @"CAPABILITY";


@interface LBIMAPConnection ()
- (void)endIDLE;
@end

@implementation LBIMAPConnection

@synthesize needsToExpunge;
@synthesize currentlySelectMailbox;

- (id)initWithAccount:(LBAccount*)anAccount {
    
    IPAddress *addr = [IPAddress addressWithHostname:[anAccount imapServer] port:[anAccount imapPort]];
    self = [self initToAddress:addr];
    
	if (self != nil) {
        
        [self setAccount:anAccount];
        
        if ([[self account] imapTLS]) {
            
            NSMutableDictionary *sslProps = [NSMutableDictionary dictionary];
            
            [sslProps setObject:[NSNumber numberWithBool:YES] forKey:(id)kTCPPropertySSLAllowsAnyRoot];
            [sslProps setObject:[NSNull null] forKey:(id)kCFStreamSSLPeerName];
            [sslProps setObject:NSStreamSocketSecurityLevelTLSv1 forKey:(id)kCFStreamSSLLevel];
            
            [self setSSLProperties:sslProps];
        }
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [currentlySelectMailbox release];
    [super dealloc];
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


- (void)findCapabilityWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBCAPABILITY withArgument:nil readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *firstLine   = [[self responseBytes] lbFirstLine];
        NSString *expectedBAD = [NSString stringWithFormat:@"%d BAD", commandCount];
        NSString *expectedNO  = [NSString stringWithFormat:@"%d NO",  commandCount];
        
        if ([firstLine hasPrefix:expectedBAD] || [firstLine hasPrefix:expectedNO]) {
            NSError *err;
            NSString *junk = [NSString stringWithFormat:@"Could not find capiblity: %@", [self responseAsString]];
            LBQuickError(&err, LBCAPABILITY, 0, junk);
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        if (!lastLine) {
            return;
        }
        
        NSString *expectedOK  = [NSString stringWithFormat:@"%d OK",  commandCount];
        
        if ([lastLine hasPrefix:expectedOK]) {
            
            // need to parse the sucker now.
            
            [self callBlockWithError:nil killReadBlock:YES];
        }
        else {
            // we're just waiting for more data.
        }
        
    }];
}

- (void)loginWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    NSString *loginArgument = [NSString stringWithFormat:@"%@ %@", [[self account] username], [[self account] password]];
    
    [self sendCommand:LBLOGIN withArgument:loginArgument readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *res = [[self responseBytes] lbSingleLineResponse];
        
        if (!res) {
            return;
        }
        
        NSString *expected = [NSString stringWithFormat:@"%d OK", commandCount];
        
        BOOL worked = [res hasPrefix:expected];
        
        NSError *err = nil;
        
        if (!worked) {
            LBQuickError(&err, LBLOGIN, 0, [NSString stringWithFormat:@"Could not login, got '%@' expected '%@'", res, expected]);
        }
        
        [self callBlockWithError:err killReadBlock:YES];
    }];
}

- (void)selectMailbox:(NSString*)mailbox block:(LBResponseBlock)block {
    
    if (!mailbox) {
        debug(@"bad mailbox!");
    }
    
    if ([mailbox isEqualToString:currentlySelectMailbox]) {
        block(nil);
        return;
    }
    
    responseBlock = [block copy];
    
    NSString *selectArg = [NSString stringWithFormat:@"\"%@\"", mailbox];
    
    [self sendCommand:LBSELECT withArgument:selectArg readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *firstLine   = [[self responseBytes] lbFirstLine];
        NSString *expectedBAD = [NSString stringWithFormat:@"%d BAD", commandCount];
        NSString *expectedNO  = [NSString stringWithFormat:@"%d NO",  commandCount];
        
        if ([firstLine hasPrefix:expectedBAD] || [firstLine hasPrefix:expectedNO]) {
            NSError *err;
            NSString *junk = [NSString stringWithFormat:@"Could not Select mailbox: %@", [self responseAsString]];
            LBQuickError(&err, LBSELECT, 0, junk);
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        
        if (!lastLine) {
            return;
        }
        
        NSString *expectedOK  = [NSString stringWithFormat:@"%d OK",  commandCount];
        
        if ([lastLine hasPrefix:expectedOK]) {
            
            [mailbox retain];
            [currentlySelectMailbox release];
            currentlySelectMailbox = mailbox;
            
            [self callBlockWithError:nil killReadBlock:YES];
        }
        
        // else, we're still reading.
    }];
}

- (void)listMessagesWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBSEARCH withArgument:@"ALL" readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *expected      = [NSString stringWithFormat:@"%d OK", commandCount];
        NSString *expectedErr   = [NSString stringWithFormat:@"%d NO", commandCount];
        NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD", commandCount];
        NSString *lastLine      = [[self responseBytes] lbLastLineOfMultiline];
        
        if ([lastLine hasPrefix:expected]) {
            
            // FIXME: check for correctness
            [self callBlockWithError:nil killReadBlock:YES];
        }
        else if ([lastLine hasPrefix:expectedErr] || [lastLine hasPrefix:expectedBad]) {
            
            NSError *err    = nil;
            NSString *junk  = [NSString stringWithFormat:@"Could not search mailbox: %@", [self responseAsString]];
            
            LBQuickError(&err, LBSEARCH, 0, junk);
            
            [self callBlockWithError:err killReadBlock:YES];
        }
    }];
}

- (void)listSubscribedMailboxesWithBock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    // http://tools.ietf.org/html/rfc3501#section-6.3.9
    
    [self sendCommand:LBLSUB withArgument:@"\"\" \"*\"" readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *firstLine     = [[self responseBytes] lbFirstLine];
        NSString *expectedNo    = [NSString stringWithFormat:@"%d NO", commandCount];
        NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD", commandCount];
        
        if ([firstLine hasPrefix:expectedBad] || [firstLine hasPrefix:expectedNo]) {
            NSError *err;
            NSString *junk = [NSString stringWithFormat:@"Could not LSUB mailbox: %@", [self responseAsString]];
            LBQuickError(&err, LBLSUB, 0, junk);
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        NSString *expected = [NSString stringWithFormat:@"%d OK", commandCount];
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        
        if ([lastLine hasPrefix:expected]) {
            // FIXME: check for correctness
            [self callBlockWithError:nil killReadBlock:YES];
        }
        
    }];
}

- (void)idleWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBIDLE withArgument:nil];
}


- (void)connectUsingBlock:(LBResponseBlock)block {
    
    [(LBTCPReader*)[self reader] setCanReadBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *res = [[self responseBytes] lbSingleLineResponse];
        
        if (!res) {
            return;
        }
        
        [self callBlockWithError:nil killReadBlock:YES];
        
    }];
    
    [super connectUsingBlock:block];
}


- (void)logoutWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBLOGOUT withArgument:nil readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *lastLine      = [[self responseBytes] lbFirstLine];
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
        
        [self callBlockWithError:err killReadBlock:YES];
    }];
}

- (void) simpleCommand:(NSString*)command withArgument:(NSString*)arg block:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:command withArgument:arg readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *res = [[self responseBytes] lbSingleLineResponse];
        
        if (!res) {
            return;
        }
        
        NSString *expected = [NSString stringWithFormat:@"%d OK ", commandCount];
        
        BOOL worked = [res hasPrefix:expected];
        
        NSError *err = nil;
        
        if (!worked) {
            // FIXME: pick up on the name of the mailbox here.
            NSString *junk = [NSString stringWithFormat:@"Error for %@: '%@'", currentCommand, expected];
            LBQuickError(&err, command, 0, junk);
        }
        
        [self callBlockWithError:err killReadBlock:YES];
    }];
    
}

- (void)createMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    [self simpleCommand:LBCREATE withArgument:mailboxName block:block];
}

- (void)deleteMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    [self simpleCommand:LBDELETE withArgument:mailboxName block:block];
}

- (void)subscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    [self simpleCommand:LBSUBSCRIBE withArgument:mailboxName block:block];
}

- (void)unsubscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block {
    [self simpleCommand:LBUNSUBSCRIBE withArgument:mailboxName block:block];
}


- (void)deleteMessageWithUID:(NSString*)serverUID withBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    // 123 UID STORE 456 +FLAGS.SILENT (\Deleted)
    
    // we're really just setting a flag on the message.
    NSString *format = [NSString stringWithFormat:@"UID STORE %@ +FLAGS.SILENT (\\Deleted)", serverUID];
    
    [self sendCommand:format withArgument:nil readBlock:^(LBTCPReader *reader) {
        [self appendDataFromReader:reader];
        
        NSString *line = [[self responseBytes] lbSingleLineResponse];
        
        if (!line) {
            return;
        }
        
        NSString *expectedGood  = [NSString stringWithFormat:@"%d OK", commandCount, CRLF];
        NSError *err            = nil;
        
        if (![line hasPrefix:expectedGood]) {
            LBQuickError(&err, @"UID STORE", 0, line);
        }
        
        [self callBlockWithError:err killReadBlock:YES];
        
    }];
}








- (void)deleteMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    // we're really just setting a flag on the message.
    NSString *format = [NSString stringWithFormat:@"%@ +FLAGS (\\Deleted)", seqIds];
    
    [self sendCommand:LBSTORE withArgument:format readBlock:^(LBTCPReader *reader) {
        [self appendDataFromReader:reader];
        
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        
        if (!lastLine) {
            return;
        }
        
        NSString *expectedGood  = [NSString stringWithFormat:@"%d OK", commandCount, CRLF];
        NSError *err = nil;
        
        if ([lastLine hasPrefix:expectedGood]) {
            [self callBlockWithError:err killReadBlock:YES];
        }
        else {
            /// dot dot dot ?
        }
        
    }];
}

- (void)expungeWithBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    [self sendCommand:LBEXPUNGE withArgument:nil readBlock:^(LBTCPReader *reader) {
        [self appendDataFromReader:reader];
        
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        
        if (!lastLine) {
            return;
        }
        
        NSString *expectedGood  = [NSString stringWithFormat:@"%d OK", commandCount, CRLF];
        NSError *err = nil;
        
        if ([lastLine hasPrefix:expectedGood]) {
            [self callBlockWithError:err killReadBlock:YES];
        }
        else {
            /// dot dot dot ?
        }
        
    }];
}

- (NSArray*)fetchedEnvelopes {
    NSMutableArray *ar = [NSMutableArray array];
    
    // ok, this should be the envelopes, one per line.
    
    for (NSString *line in [[self responseAsString] componentsSeparatedByString:@"\r\n"]) {
        
        if (![line hasPrefix:@"*"]) {
            continue;
        }
        
        NSDictionary *d = LBParseSimpleFetchResponse(line);
        
        if (d) {
            [ar addObject:d];
        }
        else {
            NSLog(@"Could not parse '%@'", line);
        }
        
    }
    
    return ar;
}

- (void)copyMessage:(LBMessage*)message toMailbox:(NSString*)destMailbox withBlock:(LBResponseBlock)block {
    
    responseBlock = [block copy];
    
    // we're really just setting a flag on the message.
    NSString *format = [NSString stringWithFormat:@"UID COPY %@ \"%@\"", [message serverUID], destMailbox];
    
    [self sendCommand:format withArgument:nil readBlock:^(LBTCPReader *reader) {
        [self appendDataFromReader:reader];
        
        NSString *line = [[self responseBytes] lbSingleLineResponse];
        
        if (!line) {
            return;
        }
        
        // FIXME: look for the copyuid stuff ([COPYUID 1049043632 390 98802])
        
        NSString *expectedGood  = [NSString stringWithFormat:@"%d OK", commandCount, CRLF];
        NSError *err            = nil;
        
        if (![line hasPrefix:expectedGood]) {
            LBQuickError(&err, @"UID COPY", 0, line);
        }
        
        [self callBlockWithError:err killReadBlock:YES];
        
    }];
}

- (void)fetchEnvelopes:(NSString*)seqIds withBlock:(LBResponseBlock)block {
    // http://tools.ietf.org/html/rfc3501#section-6.4.5
    responseBlock = [block copy];
    
    NSString *format = [NSString stringWithFormat:@"%@ (FLAGS INTERNALDATE RFC822.SIZE ENVELOPE UID)", seqIds];
    
    [self sendCommand:LBFETCH withArgument:format  readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
        
        NSString *expectedGood = [NSString stringWithFormat:@"%d OK", commandCount, CRLF];
        NSString *expectedNo   = [NSString stringWithFormat:@"%d NO", commandCount, CRLF];
        NSString *expectedBad  = [NSString stringWithFormat:@"%d BAD", commandCount, CRLF];
        
        if ([lastLine hasPrefix:expectedNo] || [lastLine hasPrefix:expectedBad]) {
            NSError *err = nil;
            LBQuickError(&err, LBFETCH, 0, lastLine);
            [self callBlockWithError:err killReadBlock:YES];
            return;
        }
        
        if (![lastLine hasPrefix:expectedGood]) {
            return;
        }
        
        [self callBlockWithError:nil killReadBlock:YES];
    }];
}

- (void)fetchMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block {
    responseBlock = [block copy];
    
    #warning make sure we do a peek here, so it doesn't get marked as read.
    
    NSString *format = [NSString stringWithFormat:@"%@ (RFC822)", seqIds];
    
    [self sendCommand:LBFETCH withArgument:format  readBlock:^(LBTCPReader *reader) {
        
        [self appendDataFromReader:reader];
        
        NSString *firstLine = [[self responseBytes] lbFirstLine];
        
        if (firstLine) {
            
            // * 1 FETCH (RFC822 {2668}'
            
            // FIXME: this happens sometimes, and we throw an assert in that case:
            // * 882 FETCH ()
            
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
            
            if ([[self responseBytes] length] > atLeastLength) {
                
                NSString *lastLine      = [[self responseBytes] lbLastLineOfMultiline];
                NSString *expectedGood  = [NSString stringWithFormat:@"%d OK FETCH", commandCount, CRLF];
                //NSString *expectedNo    = [NSString stringWithFormat:@"%d NO", commandCount, CRLF];
                //NSString *expectedBad   = [NSString stringWithFormat:@"%d BAD", commandCount, CRLF];
                
                NSError *err = nil;
                
                if ([lastLine hasPrefix:expectedGood]) {
                    
                    [self callBlockWithError:err killReadBlock:YES];
                }
                
            }
            
            // 10 OK FETCH completed.
            
            // * 1 FETCH (RFC822 {2668} crlf + 2668 bytes of data + crlf + ) + crlf + 10 OK FETCH completed.
            
        }
    }];
    
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
    
    NSString *lastLine = [[self responseBytes] lbLastLineOfMultiline];
    
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
    
    if ([[self responseBytes] length] < (headerLen + currentFetchingMessageSize)) {
        NSLog(@"There isn't enough data for the last message.  Are you calling too soon?");
        return nil;
    }
    
    NSData *data = [[self responseBytes] subdataWithRange:NSMakeRange(headerLen, currentFetchingMessageSize)];
    
    return data;
}

@end

