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

#import "LBAddressTests.h"


@implementation LBAddressTests

- (void)testEquals {
	LBAddress *addr1 = [LBAddress addressWithName:@"Matt" email:@"test@test.com"];
	LBAddress *addr2 = [LBAddress addressWithName:@"Matt" email:@"test@test.com"];
	STAssertTrue([addr1 isEqual:addr2], @": testEquals - LBAddress should have been equal!");
}

- (void)testNotEqual {
	LBAddress *addr1 = [LBAddress addressWithName:@"" email:@"something@some.com"];
	LBAddress *addr2 = [LBAddress addressWithName:@"Something" email:@"something@some.com"];
	STAssertFalse([addr1 isEqual:addr2], @": testNotEqual - LBAddress should not have been equal!");
}

- (void)testDecodedName {
    LBAddress *addr = [[LBAddress alloc] init];

    [addr setName:@"=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"Keld Jørn Simonsen"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?US-ASCII?Q?Keith_Moore?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"Keith Moore"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?Andr=E9?= Pirard"]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"André Pirard"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?iso-8859-8?b?7eXs+SDv4SDp7Oj08A==?="]; // RFC 2047 Example
    // FIXME: jasonrm - I don't know what the correct decoded string is... yet.
    STAssertTrue([[addr decodedName] isEqual:@"Unknown"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"a"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a?= b"]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"a b"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a?= =?ISO-8859-2?Q?_b?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"a b"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a?= =?ISO-8859-1?Q?b?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"ab"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a_b?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"a b"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-1?Q?a?=\r\n      =?ISO-8859-1?Q?b?="]; // RFC 2047 Example
    STAssertTrue([[addr decodedName] isEqual:@"ab"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-15?Q?Gabriel_H=F6hener?="]; // Custom Case
    STAssertTrue([[addr decodedName] isEqual:@"Gabriel Höhener"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?ISO-8859-2?Q?Mario_Ku=B9njer?="]; // Custom Case
    STAssertTrue([[addr decodedName] isEqual:@"Mario Kušnjer"], @"Decoding failed. Result was [%@]", [addr decodedName]);

    [addr setName:@"=?utf-8?Q?Jan_Erik_Mostr=C3=B6?= =?utf-8?Q?m?="]; // Custom Case
    STAssertTrue([[addr decodedName] isEqual:@"Jan Erik Moström"], @"Decoding failed. Result was [%@]", [addr decodedName]);
}

@end
