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
    
    LBMIMEMessage *mm = [[LBMIMEParser messageFromString:message] autorelease];
    
    GHAssertNotNil(mm, @"Creation of a LBMIMEMessage");
    GHAssertEqualStrings([mm boundary], @"===============0703719983==", @"Checking the boundry");
    GHAssertTrue([[mm contentType] hasPrefix:@"multipart/mixed"], @"Checking the contentType");
    GHAssertTrue([[mm subparts] count] == 2, @"the count of subparts");
    GHAssertTrue([mm isMultipart], @"checking that yes indeed it isMultipartAlternative");
    
    GHAssertTrue([[[[mm subparts] objectAtIndex:0] contentType] hasPrefix:@"multipart/alternative"], @"the type of the first subpart");
    GHAssertTrue([[[[mm subparts] objectAtIndex:1] contentType] hasPrefix:@"text/plain"], @"the type of the second subpart");
    
    LBMIMEMessage *nosuchpart = [mm partForType: @"image/jpeg"];
    GHAssertNil(nosuchpart, @"no such part");
    
    LBMIMEMessage *altpart = [mm partForType: @"multipart/alternative"];
    GHAssertNotNil(altpart, @"the alternative part");
    GHAssertTrue([[altpart subparts] count] == 2, @"two sub-parts in altpart");
    
    LBMIMEMessage *subpart_text = [[altpart subparts] objectAtIndex:0];
    GHAssertTrue([[subpart_text contentType] hasPrefix:@"text/plain"], @"the type of the text alternative part");
    GHAssertTrue([[subpart_text content] hasPrefix:@"\nOn Jan 17, 2010, at 9:13 PM, Joseph"], @"subpart_text begins with the right text");
    GHAssertTrue([[subpart_text content] hasSuffix:@"Regards,\nBoone\n"], @"subpart_text ends with the right text");
    
    LBMIMEMessage *subpart_html = [[altpart subparts] objectAtIndex:1];
    GHAssertTrue([[subpart_html contentType] hasPrefix:@"text/html"], @"the type of the html alternative part");
    GHAssertTrue([[subpart_html content] hasPrefix:@"<html><head></head><body style"], @"subpart_html starts with the right text");
    GHAssertTrue([[subpart_html content] rangeOfString:@"<blockquote type=\"cite\">Also, let's learn some IMAP."].location != NSNotFound, @"subpart_html contains the right substring");
    GHAssertTrue([[subpart_html content] hasSuffix:@"<br>Boone</div></body></html>"], @"subpart_html ends with the right text");
    
    LBMIMEMessage *textpart = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"text/plain", @"text/html", nil]];
    
    GHAssertNotNil(textpart, @"the part");
    
    
    GHAssertEqualStrings([textpart content], @"Hello sir, this is the content, and honestly it isn't much.  Sorry.\n\nLinebreak!", @"Checking the content");
    
    textpart = [mm availablePartForTypeFromArray:[NSArray arrayWithObjects: @"multipart/alternative", nil]];
    
    
    GHAssertNotNil(textpart, @"the multipart part");
    
    
}

- (void) testBoundaryWarts {
    NSString *source = (@"From nobody Fri Apr  2 23:31:22 2010\n"
                        "Content-Type: MULTIPART/MIXED; boundary=ZZZZ \n"  // uppercase type, whitespace at end of boundary
                        "\n"
                        "--ZZZZ\n"
                        "Content-Type: text/plain; charset=\"us-ascii\"\n"
                        "Content-Transfer-Encoding: 7bit\n"
                        "\n"
                        "Hello world!\n"
                        "--ZZZZ--");
    LBMIMEMessage *message = [[LBMIMEParser messageFromString:source] autorelease];
    
    GHAssertTrue([message isMultipart], @"message is multi-part");
    GHAssertTrue([[message subparts] count] == 1, @"one message part");
    LBMIMEMessage *textpart = [[message subparts] objectAtIndex:0];
    GHAssertTrue([[textpart contentType] hasPrefix:@"text/plain"], @"proper content-type for part");
    GHAssertTrue([[textpart content] isEqualToString:@"Hello world!"], @"proper content for text part");
}

- (void) testBase64 {
    NSString *source = (@"From nobody Fri Apr  2 23:31:22 2010\n"
                        "Content-Type: MULTIPART/MIXED; boundary=ZZZZ \n"  // uppercase type, whitespace at end of boundary
                        "\n"
                        "--ZZZZ\n"
                        "Content-Type: somerandom/mimetype\n"
                        "MIME-Version: 1.0\n"
                        "Content-Transfer-Encoding: base64\n"
                        "\n"
                        "U09NRSBia\n"
                        "W5hcnkgRE\n"
                        "FUQQ==\n"
                        "--ZZZZ--");
    LBMIMEMessage *message = [[LBMIMEParser messageFromString:source] autorelease];
    
    GHAssertTrue([message isMultipart], @"message is multi-part");
    GHAssertTrue([[message subparts] count] == 1, @"one message part");
    LBMIMEMessage *binpart = [[message subparts] objectAtIndex:0];
    GHAssertTrue([[binpart contentType] hasPrefix:@"somerandom/mimetype"], @"proper content-type for part");
    debug(@"content: %@", [binpart content]);
    GHAssertTrue([[binpart decodedData] isEqualToData:[@"SOME binary DATA" dataUsingEncoding:NSASCIIStringEncoding]], @"proper content for part");
}

@end
