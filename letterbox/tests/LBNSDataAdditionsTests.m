//
//  LBNSDataAdditionsTests.m
//  LetterBox
//
//  Created by August Mueller on 2/21/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBNSDataAdditionsTests.h"
#import "LBNSDataAdditions.h"
#import "LBNSStringAdditions.h"

@implementation LBNSDataAdditionsTests

- (void)testDataStuffA {
    
    NSString *foo = @"Hello World,\r\nHow is it going?\r\n";
    NSString *expected = @"Hello World,";
    NSString *got = [[foo utf8Data] lbFirstLine];
    
    GHAssertTrue([got isEqualToString:expected], @"lbFirstLine failed");
}

- (void)testDataStuffB {
    
    NSString *foo = @"Hello World,\r\n";
    NSString *expected = @"Hello World,";
    NSString *got = [[foo utf8Data] lbFirstLine];
    
    GHAssertTrue([got isEqualToString:expected], @"lbFirstLine failed");
}

- (void)testDataStuffC {
    
    NSString *foo = @"Hello World,";
    NSString *got = [[foo utf8Data] lbFirstLine];
    
    // there's no crlf on this bit, so it should be nil.
    GHAssertTrue(!got, @"lbFirstLine failed");
}

- (void)testDataStuffD {
    
    NSString *foo = @"* LSUB (\\HasNoChildren) \".\" \"INBOX.zero\"\r\n\
...\r\n\
2 OK LSUB completed\r\n";
    
    NSString *expected = @"2 OK LSUB completed\r\n";
    
    GHAssertTrue([[foo utf8Data] lbEndIsEqualTo:expected], @"lbEndIsEqualTo failed");
}


- (void)testDataStuffE {
    
    NSString *foo = @"* LSUB (\\HasNoChildren) \".\" \"INBOX.zero\"\r\n\
...\r\n\
2 OK LSUB completed\r\n";
    
    NSString *expected = @"2 OK LSUB completed";
    
    GHAssertEqualStrings([[foo utf8Data] lbLastLineOfMultiline], expected, @"lbLastLineOfMultiline failed");
}



- (void)testDataStuffF {
    
    NSString *foo = @"2 OK LOGIN\r\n";
    NSString *expected = @"2 OK LOGIN";
    
    GHAssertEqualStrings([[foo utf8Data] lbSingleLineResponse], expected, @"lbSingleLineResponse failed");
}

- (void)testDataStuffG {
    
    NSString *foo = @"2 OK LOG..";
    
    GHAssertNil([[foo utf8Data] lbSingleLineResponse], @"lbSingleLineResponse nil failed");
}



@end
