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

- (void) testTestTesterYesirTest {
    
    NSUInteger usedEncoding;
    NSError *err = nil;
    NSString *message = [NSString stringWithContentsOfURL:[self urlToMessage:@"html1.letterbox"] usedEncoding:&usedEncoding error:&err];
    
    LBMIMEMultipartMessage *mm = [[[LBMIMEMultipartMessage alloc] initWithString:message] autorelease];
    
    for (LBMIMEPart *part in [mm subparts]) {
        NSLog(@"sub part: %@", part.contentType);
    }
    
    debug(@"mimePart.contentType: '%@'", [mm contentType]);
    
    debug(@"mm: '%@'", mm);
    
    LBMIMEPart *representation = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"text/plain", @"text/html", nil]];
    
    GHAssertNotNil(representation, @"the representation");
    
    debug(@"representation: '%@'", representation);
    
    GHAssertTrue(NO, nil);
}

@end
