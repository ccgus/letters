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
    
    LBMIMEPart *nosuchpart = [mm partForType: @"image/jpeg"];
    GHAssertNil(nosuchpart, @"no such part");
    
    LBMIMEPart *altpart = [mm partForType: @"multipart/alternative"];
    GHAssertNotNil(altpart, @"the alternative part");
    GHAssertTrue([[altpart subparts] count] == 2, @"two sub-parts in altpart");
    
    LBMIMEPart *subpart_text = [[altpart subparts] objectAtIndex:0];
    GHAssertTrue([[subpart_text contentType] hasPrefix:@"text/plain"], @"the type of the text alternative part");
    GHAssertTrue([[subpart_text content] hasPrefix:@"\nOn Jan 17, 2010, at 9:13 PM, Joseph"], @"subpart_text begins with the right text");
    GHAssertTrue([[subpart_text content] hasSuffix:@"Regards,\nBoone\n"], @"subpart_text ends with the right text");
    
    LBMIMEPart *subpart_html = [[altpart subparts] objectAtIndex:1];
    GHAssertTrue([[subpart_html contentType] hasPrefix:@"text/html"], @"the type of the html alternative part");
    GHAssertTrue([[subpart_html content] hasPrefix:@"<html><head></head><body style"], @"subpart_html starts with the right text");
    GHAssertTrue([[subpart_html content] rangeOfString:@"<blockquote type=\"cite\">Also, let's learn some IMAP."].location != NSNotFound, @"subpart_html contains the right substring");
    GHAssertTrue([[subpart_html content] hasSuffix:@"<br>Boone</div></body></html>"], @"subpart_html ends with the right text");
    
    LBMIMEPart *textpart = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"text/plain", @"text/html", nil]];
    
    GHAssertNotNil(textpart, @"the part");
    
    
    GHAssertEqualStrings([textpart content], @"Hello sir, this is the content, and honestly it isn't much.  Sorry.\n\nLinebreak!", @"Checking the content");
    
    textpart = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"multipart/alternative", nil]];
    
    
    GHAssertNotNil(textpart, @"the multipart part");
    
    
}

@end
