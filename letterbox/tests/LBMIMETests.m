/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "LBMIMETests.h"

#import "LBMessage.h"
#import "LBMIME.h"
#import <libetpan/libetpan.h>
#import "LBMIMEFactory.h"
#import "LBMIME_MessagePart.h"
#import "LBMIME_MultiPart.h"
#import "LBMIME_SinglePart.h"
#import "LBMIME_TextPart.h"
#import "LBMIME_Enumerator.h"

const NSString *filePrefix = @"/Users/jason/git-local/letters/letterbox/";

@implementation LBMIMETests
- (void)testMIMETextPart {
	LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:[NSString stringWithFormat:@"%@%@",filePrefix,@"TestData/kiwi-dev/1167196014.6158_0.theronge.com:2,Sab"]];
	LBMIME *mime = [LBMIMEFactory createMIMEWithMIMEStruct:[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	STAssertTrue([mime isKindOfClass:[LBMIME_MessagePart class]],@"Outmost MIME type should be Message but it's not!");
	STAssertTrue([[mime content] isKindOfClass:[LBMIME_MultiPart class]],@"Incorrect MIME structure found!");
	NSArray *multiPartContent = [[mime content] content];
	STAssertTrue([multiPartContent count] == 2, @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:0] isKindOfClass:[LBMIME_TextPart class]], @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:1] isKindOfClass:[LBMIME_TextPart class]], @"Incorrect MIME structure found!");	
	[msg release];
}

- (void)testSmallMIME {
	LBMIME_TextPart *text1 = [LBMIME_TextPart mimeTextPartWithString:@"Hello there!"];
	LBMIME_TextPart *text2 = [LBMIME_TextPart mimeTextPartWithString:@"This is part 2"];
	LBMIME_MultiPart *multi = [LBMIME_MultiPart mimeMultiPart];
	[multi addMIMEPart:text1];
	[multi addMIMEPart:text2];
	LBMIME_MessagePart *messagePart = [LBMIME_MessagePart mimeMessagePartWithContent:multi];
	NSString *str = [messagePart render];
	[str writeToFile:@"/tmp/mailcore_test_output" atomically:NO encoding:NSASCIIStringEncoding error:NULL];
	
	LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:@"/tmp/mailcore_test_output"];
	LBMIME *mime = [LBMIMEFactory createMIMEWithMIMEStruct:[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	STAssertTrue([mime isKindOfClass:[LBMIME_MessagePart class]],@"Outmost MIME type should be Message but it's not!");
	STAssertTrue([[mime content] isKindOfClass:[LBMIME_MultiPart class]],@"Incorrect MIME structure found!");
	NSArray *multiPartContent = [[mime content] content];	
	STAssertTrue([multiPartContent count] == 2, @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:0] isKindOfClass:[LBMIME_TextPart class]], @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:1] isKindOfClass:[LBMIME_TextPart class]], @"Incorrect MIME structure found!");
	[msg release];
}

- (void)testBruteForce {
	// run it on a bunch of the files in the test data directory and see if we can get it to crash
	NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[filePrefix stringByAppendingString:@"TestData/kiwi-dev/"]];
	NSString *file;
	NSRange notFound = NSMakeRange(NSNotFound, 0);
	while ((file = [dirEnumerator nextObject])) {
		if (!NSEqualRanges([file rangeOfString:@".svn"],notFound))
			continue;
		LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:[NSString stringWithFormat:@"%@TestData/kiwi-dev/%@",filePrefix,file]];
		NSLog([msg subject]);
		[msg fetchBody];
		NSString *stuff = [msg body];
		[stuff length]; //Get the warning to shutup about stuff not being used
		[msg release];
	}
}

- (void)testImageJPEGAttachment {
	LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:[NSString stringWithFormat:@"%@%@",filePrefix,@"TestData/mime-tests/imagetest"]];
	LBMIME *mime = [LBMIMEFactory createMIMEWithMIMEStruct:[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	STAssertTrue([mime isKindOfClass:[LBMIME_MessagePart class]],@"Outmost MIME type should be Message but it's not!");
	STAssertTrue([[mime content] isKindOfClass:[LBMIME_MultiPart class]],@"Incorrect MIME structure found!");
	NSArray *multiPartContent = [[mime content] content];	
	STAssertTrue([multiPartContent count] == 3, @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:0] isKindOfClass:[LBMIME_TextPart class]], @"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:1] isKindOfClass:[LBMIME_SinglePart class]], @"Incorrect MIME structure found!");
	LBMIME_SinglePart *img = [multiPartContent objectAtIndex:1];	
	STAssertTrue(img.attached == FALSE, @"Image is should be inline");
	STAssertEqualObjects(img.filename, @"mytestimage.jpg", @"Filename of inline image not correct");
	[msg release];
}

- (void)testImagePNGAttachment {
	LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:
				[NSString stringWithFormat:@"%@%@",filePrefix,@"TestData/mime-tests/png_attachment"]];
	LBMIME *mime = [LBMIMEFactory createMIMEWithMIMEStruct:
						[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	STAssertTrue([mime isKindOfClass:[LBMIME_MessagePart class]],
					@"Outmost MIME type should be Message but it's not!");
	STAssertTrue([[mime content] isKindOfClass:[LBMIME_MultiPart class]],
					@"Incorrect MIME structure found!");
	NSArray *multiPartContent = [[mime content] content];	
	STAssertTrue([multiPartContent count] == 2, 
					@"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:0] isKindOfClass:[LBMIME_TextPart class]], 
					@"Incorrect MIME structure found!");
	STAssertTrue([[multiPartContent objectAtIndex:1] isKindOfClass:[LBMIME_SinglePart class]], 
					@"Incorrect MIME structure found!");
	LBMIME_SinglePart *img = [multiPartContent objectAtIndex:1];	
	STAssertTrue(img.attached == TRUE, @"Image is should be attached");
	STAssertEqualObjects(img.filename, @"Picture 1.png", @"Filename of inline image not correct");
	[msg release];
}

- (void)testEnumerator {
	LBMessage *msg = [[LBMessage alloc] initWithFileAtPath:
				[NSString stringWithFormat:@"%@%@",filePrefix,@"TestData/mime-tests/png_attachment"]];
	LBMIME *mime = [LBMIMEFactory createMIMEWithMIMEStruct:
						[msg messageStruct]->msg_mime forMessage:[msg messageStruct]];
	LBMIME_Enumerator *enumerator = [mime mimeEnumerator];
	NSArray *allObjects = [enumerator allObjects];
	STAssertTrue([[allObjects objectAtIndex:0] isKindOfClass:[LBMIME_MessagePart class]], 
					@"Incorrect MIME structure found!");
	STAssertEqualObjects([[allObjects objectAtIndex:0] contentType], @"message/rfc822",
							@"found incorrect contentType");
	STAssertTrue([[allObjects objectAtIndex:1] isKindOfClass:[LBMIME_MultiPart class]], 
					@"Incorrect MIME structure found!");
	STAssertEqualObjects([[allObjects objectAtIndex:1] contentType], @"multipart/mixed",
							@"found incorrect contentType");					
	STAssertTrue([[allObjects objectAtIndex:2] isKindOfClass:[LBMIME_TextPart class]], 
					@"Incorrect MIME structure found!");
	STAssertEqualObjects([[allObjects objectAtIndex:2] contentType], @"text/plain",
							@"found incorrect contentType");					
	STAssertTrue([[allObjects objectAtIndex:3] isKindOfClass:[LBMIME_SinglePart class]], 
					@"Incorrect MIME structure found!");
	STAssertEqualObjects([[allObjects objectAtIndex:3] contentType], @"image/png",
							@"found incorrect contentType");															
	STAssertTrue([enumerator nextObject] == nil, @"Should have been nil");
	NSArray *fullAllObjects = allObjects;
	
	enumerator = [[mime content] mimeEnumerator];
	allObjects = [enumerator allObjects];
	STAssertTrue([[allObjects objectAtIndex:0] isKindOfClass:[LBMIME_MultiPart class]], 
					@"Incorrect MIME structure found!");
	STAssertTrue([[allObjects objectAtIndex:1] isKindOfClass:[LBMIME_TextPart class]], 
					@"Incorrect MIME structure found!");
	STAssertTrue([[allObjects objectAtIndex:2] isKindOfClass:[LBMIME_SinglePart class]], 
					@"Incorrect MIME structure found!");										
	STAssertTrue([enumerator nextObject] == nil, @"Should have been nil");
	
	enumerator = [[[[mime content] content] objectAtIndex:0] mimeEnumerator];
	allObjects = [enumerator allObjects];
	STAssertTrue([[allObjects objectAtIndex:0] isKindOfClass:[LBMIME_TextPart class]], 
					@"Incorrect MIME structure found!");	
	STAssertTrue([enumerator nextObject] == nil, @"Should have been nil");
	
	enumerator = [mime mimeEnumerator];
	NSMutableArray *objects = [NSMutableArray array];
	LBMIME *obj;
	while ((obj = [enumerator nextObject])) {
		[objects addObject:obj];
	}
	STAssertEqualObjects(objects, fullAllObjects, @"nextObject isn't iterating over the same objects ast allObjects");
}
@end
