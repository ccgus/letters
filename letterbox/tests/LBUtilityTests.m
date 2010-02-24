//
//  LBUtilityTests.m
//  LetterBox
//
//  Created by August Mueller on 2/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBUtilityTests.h"
#import "LetterBoxUtilities.h"

@implementation LBUtilityTests

- (void)testFetchResponse1 {
    
    NSString *s = @"* 1 FETCH (FLAGS (\\Seen $NotJunk NotJunk) INTERNALDATE \"29-Jan-2010 21:44:05 -0800\" RFC822.SIZE 15650 ENVELOPE (\"Wed, 27 Jan 2010 22:51:51 +0000\" \"Re: Coding Style Guidelines\" ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Bob Smith\" NIL \"bobsmith\" \"gmail.com\")) ((\"Gus Mueller\" NIL \"gus\" \"lettersapp.com\")) NIL NIL \"<4CE4C6F7-A466-4060-8FC6-4FEF66C6B906lettersapp.com>\" \"<8f5c05b71001271451j72710a29ia54773d3r743182c@mail.gmail.com>\") UID 98656)";
    
    
    NSDictionary *res = LBParseSimpleFetchResponse(s);
    
    NSLog(@"res: %@", res);
    
    GHAssertEqualStrings([res objectForKey:@"FLAGS"], @"(\\Seen $NotJunk NotJunk)", @"Flags");
    GHAssertEqualStrings([res objectForKey:@"INTERNALDATE"], @"29-Jan-2010 21:44:05 -0800", @"INTERNALDATE");
    GHAssertEqualStrings([res objectForKey:@"RFC822.SIZE"], @"15650", @"RFC822.SIZE");
    
}

@end
