//
//  LBUtilityTests.m
//  LetterBox
//
//  Created by August Mueller on 2/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBUtilityTests.h"
#import "LetterBoxUtilities.h"
#import "LBAddress.h"

@implementation LBUtilityTests

- (void)testFetchResponse1 {
    
    NSString *s = @"* 1 FETCH (FLAGS (\\Seen $NotJunk NotJunk) INTERNALDATE \"29-Jan-2010 21:44:05 -0800\" RFC822.SIZE 15650 ENVELOPE (\"Wed, 27 Jan 2010 22:51:51 +0000\" \"Re: Coding Style Guidelines\" ((\"Bob Smith\" \"\" \"bobsmith\" \"gmail.com\")) ((\"Foo Smith\" NIL \"foosmith\" \"gmail.com\") (\"Crazy Smith\" NIL \"crazysmith\" \"gmail.com\")) ((NIL NIL \"bobsmith\" \"gmail.com\")) ((\"Gus Mueller\" NIL \"gus\" \"lettersapp.com\")) NIL NIL \"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>\" \"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>\") UID 98656)";
    
    
    NSDictionary *res = LBParseSimpleFetchResponse(s);
    
    GHAssertEqualStrings([res objectForKey:@"FLAGS"], @"\\Seen $NotJunk NotJunk", @"Flags");
    GHAssertEqualStrings([res objectForKey:@"INTERNALDATE"], @"29-Jan-2010 21:44:05 -0800", @"INTERNALDATE");
    GHAssertEqualStrings([res objectForKey:@"RFC822.SIZE"], @"15650", @"RFC822.SIZE");
    GHAssertEqualStrings([res objectForKey:@"UID"], @"98656", @"UID");
    
    GHAssertEqualStrings([res objectForKey:@"date"], @"Wed, 27 Jan 2010 22:51:51 +0000", @"envelope date");
    GHAssertEqualStrings([res objectForKey:@"subject"], @"Re: Coding Style Guidelines", @"envelope subject");
    GHAssertEqualStrings([res objectForKey:@"in-reply-to"], @"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>", @"in-reply-to");
    GHAssertEqualStrings([res objectForKey:@"message-id"], @"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>", @"message-id");
    
    
    // @"from", @"sender", @"reply-to", @"to", @"cc", @"bcc", nil];
    NSArray *fromArray      = [res objectForKey:@"from"];
    NSArray *senderArray    = [res objectForKey:@"sender"];
    NSArray *replytoArray   = [res objectForKey:@"reply-to"];
    NSArray *toArray        = [res objectForKey:@"to"];
    NSArray *ccArray        = [res objectForKey:@"cc"];
    NSArray *bccArray       = [res objectForKey:@"bcc"];
    
    GHAssertNotNil(fromArray, @"fromArray");
    GHAssertNotNil(senderArray, @"senderArray");
    GHAssertNotNil(replytoArray, @"replytoArray");
    GHAssertNotNil(toArray, @"toArray");
    GHAssertNil(ccArray, @"ccArray");
    GHAssertNil(bccArray, @"bccArray");
    
    LBAddress *addr = [fromArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Bob Smith", @"address name");
    GHAssertEqualStrings([addr email], @"bobsmith@gmail.com", @"address name");
    
    
    addr = [senderArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Foo Smith", @"address name");
    GHAssertEqualStrings([addr email], @"foosmith@gmail.com", @"address name");
    
    addr = [senderArray objectAtIndex:1];
    GHAssertEqualStrings([addr name], @"Crazy Smith", @"address name");
    GHAssertEqualStrings([addr email], @"crazysmith@gmail.com", @"address name");
    
    addr = [replytoArray objectAtIndex:0];
    GHAssertNil([addr name], @"address name");
    GHAssertEqualStrings([addr email], @"bobsmith@gmail.com", @"address name");
    
    addr = [toArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Gus Mueller", @"address name");
    GHAssertEqualStrings([addr email], @"gus@lettersapp.com", @"address name");
    
}

- (void) testFetchResponse2 {
    
    NSString *s = @"* 1 FETCH (FLAGS (\\Seen $NotJunk NotJunk) INTERNALDATE \"29-Jan-2010 21:44:05 -0800\" RFC822.SIZE 15650 ENVELOPE (\"Wed, 27 Jan 2010 22:51:51 +0000\" \"Re: Coding Style Guidelines\" ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" \"\" \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) NIL ((\"Gus Mueller\" NIL \"gus\" \"lettersapp.com\") (\"Fred Mueller\" NIL \"fred\" \"lettersapp.com\")) NIL \"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>\" \"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>\") UID 98656)";
    
    NSDictionary *res = LBParseSimpleFetchResponse(s);
    
    NSLog(@"res: '%@'", res);
    
    GHAssertEqualStrings([res objectForKey:@"FLAGS"], @"\\Seen $NotJunk NotJunk", @"Flags");
    GHAssertEqualStrings([res objectForKey:@"INTERNALDATE"], @"29-Jan-2010 21:44:05 -0800", @"INTERNALDATE");
    GHAssertEqualStrings([res objectForKey:@"RFC822.SIZE"], @"15650", @"RFC822.SIZE");
    GHAssertEqualStrings([res objectForKey:@"UID"], @"98656", @"UID");
    
    NSDictionary *envelope = [res objectForKey:@"ENVELOPE"];
    GHAssertNil(envelope, @"ENVELOPE");
    
    GHAssertEqualStrings([res objectForKey:@"date"], @"Wed, 27 Jan 2010 22:51:51 +0000", @"envelope date");
    GHAssertEqualStrings([res objectForKey:@"subject"], @"Re: Coding Style Guidelines", @"envelope subject");
    GHAssertEqualStrings([res objectForKey:@"in-reply-to"], @"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>", @"in-reply-to");
    GHAssertEqualStrings([res objectForKey:@"message-id"], @"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>", @"message-id");
    
    
    // @"from", @"sender", @"reply-to", @"to", @"cc", @"bcc", nil];
    NSArray *fromArray      = [res objectForKey:@"from"];
    NSArray *senderArray    = [res objectForKey:@"sender"];
    NSArray *replytoArray   = [res objectForKey:@"reply-to"];
    NSArray *toArray        = [res objectForKey:@"to"];
    NSArray *ccArray        = [res objectForKey:@"cc"];
    NSArray *bccArray       = [res objectForKey:@"bcc"];
    
    GHAssertNotNil(fromArray, @"fromArray");
    GHAssertNotNil(senderArray, @"senderArray");
    GHAssertNotNil(replytoArray, @"replytoArray");
    GHAssertNil(toArray, @"toArray");
    GHAssertNotNil(ccArray, @"ccArray");
    GHAssertNil(bccArray, @"bccArray");
    
    LBAddress *addr = [fromArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Bob Smith", @"address name");
    GHAssertEqualStrings([addr email], @"bobsmith@gmail.com", @"address name");
    
    addr = [senderArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Bob Smith", @"address name");
    GHAssertEqualStrings([addr email], @"bobsmith@gmail.com", @"address name");
    
    addr = [replytoArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Bob Smith", @"address name");
    GHAssertEqualStrings([addr email], @"bobsmith@gmail.com", @"address name");
    
    addr = [ccArray objectAtIndex:0];
    GHAssertEqualStrings([addr name], @"Gus Mueller", @"address name");
    GHAssertEqualStrings([addr email], @"gus@lettersapp.com", @"address name");
    
    addr = [ccArray objectAtIndex:1];
    GHAssertEqualStrings([addr name], @"Fred Mueller", @"address name");
    GHAssertEqualStrings([addr email], @"fred@lettersapp.com", @"address name");
    
    
    
}

@end
