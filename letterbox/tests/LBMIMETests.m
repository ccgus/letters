//
//  LBMIMETests.m
//  LetterBox
//
//  Created by August Mueller on 3/16/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBMIMETests.h"
#import "LBMIMEMessage.h"
#import "LBMIMEParser.h"
#import "LBMIMEGenerator.h"

#define debug NSLog

@implementation LBMIMETests

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
    
    LBMIMEMessage *mm = [LBMIMEParser messageFromString:message];
    
    GHAssertNotNil(mm, @"Creation of a LBMIMEMessage");
    GHAssertEqualStrings([mm multipartBoundary], @"===============0703719983==", @"Checking the boundry");
    GHAssertTrue([[mm contentType] hasPrefix:@"multipart/mixed"], @"Checking the contentType");
    GHAssertTrue([[mm subparts] count] == 2, @"the count of subparts");
    GHAssertTrue([mm isMultipart], @"checking that yes indeed it isMultipartAlternative");
    
    GHAssertTrue([[[[mm subparts] objectAtIndex:0] contentType] hasPrefix:@"multipart/alternative"], @"the type of the first subpart");
    GHAssertTrue([[[[mm subparts] objectAtIndex:1] contentType] hasPrefix:@"text/plain"], @"the type of the second subpart");
    
    LBMIMEMessage *altpart = [[mm subparts] objectAtIndex:0];
    GHAssertNotNil(altpart, @"the alternative part");
    GHAssertTrue([[altpart subparts] count] == 2, @"two sub-parts in altpart");
    
    LBMIMEMessage *subpart_text = [[altpart subparts] objectAtIndex:0];
    GHAssertTrue([[subpart_text contentType] hasPrefix:@"text/plain"], @"the type of the text alternative part");
    GHAssertTrue([[subpart_text content] hasPrefix:@"\nOn Jan 17, 2010, at 9:13 PM, Joseph"], @"subpart_text begins with the right text");
    GHAssertTrue([[subpart_text content] hasSuffix:@"Regards,\nBoone\n"], @"subpart_text ends with the right text");
    
    LBMIMEMessage *subpart_html = [[altpart subparts] objectAtIndex:1];
    GHAssertTrue([[subpart_html contentType] hasPrefix:@"text/html"], @"the type of the html alternative part");
    NSString *html_content = [[[NSString alloc] initWithData:[subpart_html contentTransferDecoded] encoding:NSASCIIStringEncoding] autorelease];
    GHAssertTrue([html_content hasPrefix:@"<html><head></head><body style"], @"subpart_html starts with the right text");
    GHAssertTrue([html_content rangeOfString:@"<blockquote type=\"cite\">Also, let's learn some IMAP."].location != NSNotFound, @"subpart_html contains the right substring");
    GHAssertTrue([html_content hasSuffix:@"<br>Boone</div></body></html>"], @"subpart_html ends with the right text");
    
    LBMIMEMessage *textpart = [[mm subparts] objectAtIndex:1];
    GHAssertNotNil(textpart, @"the part");
    
    GHAssertEqualStrings([textpart content], @"Hello sir, this is the content, and honestly it isn't much.  Sorry.\n\nLinebreak!", @"Checking the content");
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
    LBMIMEMessage *message = [LBMIMEParser messageFromString:source];
    
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
    LBMIMEMessage *message = [LBMIMEParser messageFromString:source];
    
    GHAssertTrue([message isMultipart], @"message is multi-part");
    GHAssertTrue([[message subparts] count] == 1, @"one message part");
    LBMIMEMessage *binpart = [[message subparts] objectAtIndex:0];
    GHAssertTrue([[binpart contentType] hasPrefix:@"somerandom/mimetype"], @"proper content-type for part");
    GHAssertTrue([[binpart contentTransferDecoded] isEqualToData:[@"SOME binary DATA" dataUsingEncoding:NSASCIIStringEncoding]], @"proper content for part");
}

- (void) testRetrieveHeaderValues {
    LBMIMEMessage *message = [LBMIMEMessage message];
    [message addHeaderWithName:@"MY-HEADER" andValue:@"hello"];
    GHAssertTrue([message headerValueForName:@"not-here"] == nil, @"nil for header-not-found");
    GHAssertTrue([[message headerValueForName:@"MY-HEADER"] isEqualToString:@"hello"], @"retrieve with same case");
    GHAssertTrue([[message headerValueForName:@"My-HeAdEr"] isEqualToString:@"hello"], @"retrieve with other case");
}

- (void) testHeaderDefect {
    NSString *source = @"Header-With-Defect\n\n\n";
    LBMIMEMessage *message = [LBMIMEParser messageFromString:source];
    GHAssertTrue([message.defects count] == 1, @"one defect");
    GHAssertTrue([[message.defects objectAtIndex:0] isEqualToString:@"Malformed header: \"Header-With-Defect\""], @"text of defect");
}

@end

@implementation LBMIMEHeaderTests

- (void) testSimple {
    NSArray *headers_src = [NSArray arrayWithObjects:
                            @"X-HEADER-ONE: header value one",
                            @"X-HEADER-TWO: second value",
                            nil];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSArray *h in [LBMIMEParser headersFromLines:headers_src defects:nil])
        [headers setObject:[h objectAtIndex:1] forKey:[h objectAtIndex:0]];
    GHAssertTrue([headers count] == 2, @"Two headers");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-ONE"] isEqualToString:@"header value one"], @"Value of first header");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-TWO"] isEqualToString:@"second value"], @"Value of second header");
}

- (void) testMultiLine {
    NSArray *headers_src = [NSArray arrayWithObjects:
                            @"X-HEADER-ONE: header value one",
                            @"   with other line",
                            @"X-HEADER-TWO: second value",
                            @"\twith its own continuation",
                            @" on multiple lines",
                            @"X-HEADER-THREE: and a third header",
                            nil];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSArray *h in [LBMIMEParser headersFromLines:headers_src defects:nil])
        [headers setObject:[h objectAtIndex:1] forKey:[h objectAtIndex:0]];
    GHAssertTrue([headers count] == 3, @"Three headers");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-ONE"] isEqualToString:@"header value one with other line"], @"Value of first header");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-TWO"] isEqualToString:@"second value with its own continuation on multiple lines"], @"Value of second header");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-THREE"] isEqualToString:@"and a third header"], @"Value of third header");
}

- (void) testDefects {
    NSArray *headers_src = [NSArray arrayWithObjects:
                            @"   a bogus continuation",
                            @"\tanother bogus continuation",
                            @"X-HEADER-OK: fine header",
                            @"X-HEADER-NO-SEPARATOR",
                            @"   with other line",
                            nil];
    NSMutableArray *defects = [NSMutableArray array];
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    for (NSArray *h in [LBMIMEParser headersFromLines:headers_src defects:defects])
        [headers setObject:[h objectAtIndex:1] forKey:[h objectAtIndex:0]];
    GHAssertTrue([headers count] == 1, @"One valid header");
    GHAssertTrue([[headers valueForKey:@"X-HEADER-OK"] isEqualToString:@"fine header"], @"Value of header");
    GHAssertTrue([defects count] == 4, @"Four defects");
    GHAssertTrue([[defects objectAtIndex:0] isEqualToString:@"Unexpected header continuation: \"   a bogus continuation\""], @"Text of first defect");
    GHAssertTrue([[defects objectAtIndex:1] isEqualToString:@"Unexpected header continuation: \"\tanother bogus continuation\""], @"Text of second defect");
    GHAssertTrue([[defects objectAtIndex:2] isEqualToString:@"Malformed header: \"X-HEADER-NO-SEPARATOR\""], @"Text of third defect");
    GHAssertTrue([[defects objectAtIndex:3] isEqualToString:@"Unexpected header continuation: \"   with other line\""], @"Text of fourth defect");
}

@end

@implementation LBMIMEPayloadTests: GHTestCase

- (void) testStringPayload {
    NSString *message_src = (@"Header: value\n"
                             @"\n"
                             @"the body here\n");
    LBMIMEMessage *message = [LBMIMEParser messageFromString:message_src];
    GHAssertTrue([message isMultipart] == NO, @"message not multipart");
    GHAssertTrue([[message content] isEqualToString:@"the body here"], @"message body");
    GHAssertTrue([[message subparts] count] == 0, @"message has no sub-messages");
    
    [message setContent:@"new body"];
    GHAssertTrue([[message content] isEqualToString:@"new body"], @"new value for body");
}

- (void) testContentTransferEncoding {
    NSString *message1_src = (@"Content-Transfer-Encoding: base64\n"
                             @"\n"
                             @"U09NRSBiaW5hcnkgREFUQQ==\n");
    LBMIMEMessage *message1 = [LBMIMEParser messageFromString:message1_src];
    GHAssertTrue([message1 isMultipart] == NO, @"message not multipart");
    GHAssertTrue([[message1 content] isEqualToString:@"U09NRSBiaW5hcnkgREFUQQ=="], @"encoded message body");
    GHAssertTrue([[message1 contentTransferDecoded] isEqualToData:[@"SOME binary DATA" dataUsingEncoding:NSASCIIStringEncoding]], @"decoded message body");
    
    NSString *message2_src = (@"Content-Transfer-Encoding: Quoted-Printable\n"
                              @"\n"
                              @"hello=20=3E=3E=20world\n");
    LBMIMEMessage *message2 = [LBMIMEParser messageFromString:message2_src];
    GHAssertTrue([message2 isMultipart] == NO, @"message not multipart");
    GHAssertTrue([[message2 content] isEqualToString:@"hello=20=3E=3E=20world"], @"encoded message body");
    GHAssertTrue([[message2 contentTransferDecoded] isEqualToData:[@"hello >> world" dataUsingEncoding:NSASCIIStringEncoding]], @"decoded message body");
}

@end

@implementation LBMIMEGeneratorTests: GHTestCase

- (void) testSimpleMessage {
    LBMIMEMessage *message = [LBMIMEMessage message];
    [message addHeaderWithName:@"My-Header" andValue:@"its value"];
    [message setContent:@"Hello world!\n"];
    NSString *expected = (@"My-Header: its value\n"
                          @"\n"
                          @"Hello world!\n");
    NSString *output = [LBMIMEGenerator stringFromMessage:message];
    GHAssertTrue([expected isEqualToString:output], @"correct output");
}

- (void) testMultipartMessage {
    LBMIMEMessage *message = [LBMIMEMessage message];
    [message addHeaderWithName:@"Content-Type" andValue:@"multipart/alternative; boundary=QQQ"];
    
    LBMIMEMessage *part1 = [LBMIMEMessage message];
    [part1 setContent:@"part one"];
    [message addSubpart:part1];
    
    LBMIMEMessage *part2 = [LBMIMEMessage message];
    [part2 setContent:@"part two"];
    [message addSubpart:part2];
    
    NSString *output = [LBMIMEGenerator stringFromMessage:message];
    NSString *expected = (@"Content-Type: multipart/alternative; boundary=QQQ\n"
                          @"\n"
                          @"--QQQ\n"
                          @"\n"
                          @"part one\n"
                          @"--QQQ\n"
                          @"\n"
                          @"part two\n"
                          @"--QQQ--");
    GHAssertTrue([expected isEqualToString:output], @"correct output");
}

@end
