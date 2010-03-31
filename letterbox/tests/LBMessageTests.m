//
//  LBMessageTests.m
//  LetterBox
//
//  Created by August Mueller on 3/16/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBMessageTests.h"
#import "LBMessage.h"

#define debug NSLog

@implementation LBMessageTests

- (NSURL*)urlToMessage:(NSString*)messageName {
    NSString *myFilePath = [NSString stringWithUTF8String:__FILE__];
    NSString *parentDir = [[myFilePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    NSString *testDir   = [[parentDir stringByAppendingPathComponent:@"tests"] stringByAppendingPathComponent:@"testmessages"];
    
    return [NSURL fileURLWithPath:[testDir stringByAppendingPathComponent:messageName]];
}

- (void) testSomeMultipartYo {
    
    NSUInteger usedEncoding;
    NSError *err = nil;
    NSString *message = [NSString stringWithContentsOfURL:[self urlToMessage:@"html1.letterbox"] usedEncoding:&usedEncoding error:&err];
    
    LBMIMEMultipartMessage *mm = [[[LBMIMEMultipartMessage alloc] initWithString:message] autorelease];
    
    GHAssertNotNil(mm, @"Creation of a LBMIMEMultipartMessage");
    GHAssertEqualStrings([mm boundary], @"===============0703719983==", @"Checking the boundry");
    GHAssertTrue([[mm contentType] hasPrefix:@"multipart/mixed"], @"Checking the contentType");
    GHAssertTrue([[mm subparts] count] == 2, @"the count of subparts");
    GHAssertTrue([mm isMultipart], @"checking that yes indeed it isMultipartAlternative");
    
    GHAssertTrue([[[[mm subparts] objectAtIndex:0] contentType] hasPrefix:@"multipart/alternative"], @"the type of the first subpart");
    GHAssertTrue([[[[mm subparts] objectAtIndex:1] contentType] hasPrefix:@"text/plain"], @"the type of the second subpart");
    
    for (LBMIMEPart *part in [mm subparts]) {
        NSLog(@"sub part: %@", part.contentType);
    }
    
    LBMIMEPart *part = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"text/plain", @"text/html", nil]];
    
    GHAssertNotNil(part, @"the part");
    
    
    GHAssertEqualStrings([part content], @"Hello sir, this is the content, and honestly it isn't much.  Sorry.\n\nLinebreak!", @"Checking the content");
    
    part = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"multipart/alternative", nil]];
    
    
    GHAssertNotNil(part, @"the multipart part");
    
    
}

@end
