//
//  Base64.m
//  MYUtilities
//
//  Created by Jens Alfke on 1/27/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//
//  Portions adapted from SSCrypto.m by Ed Silva;
//  Copyright (c) 2003-2006 Septicus Software. All rights reserved.
//  Portions taken from uncopyrighted code posted by Dave Dribin.
//

#import "Base64.h"

//NOTE: Using this requires linking against /usr/lib/libcrypto.dylib.
#import <openssl/bio.h>
#import <openssl/evp.h>


@implementation NSData (MYBase64)


/**
 * Encodes the current data in base64, and creates and returns an NSString from the result.
 * This is the same as piping data through "... | openssl enc -base64" on the command line.
 *
 * Code courtesy of DaveDribin (http://www.dribin.org/dave/)
 * Taken from http://www.cocoadev.com/index.pl?BaseSixtyFour
 **/
- (NSString *)my_base64String
{
    return [self my_base64StringWithNewlines: YES];
}

/**
 * Encodes the current data in base64, and creates and returns an NSString from the result.
 * This is the same as piping data through "... | openssl enc -base64" on the command line.
 *
 * Code courtesy of DaveDribin (http://www.dribin.org/dave/)
 * Taken from http://www.cocoadev.com/index.pl?BaseSixtyFour
 **/
- (NSString *)my_base64StringWithNewlines:(BOOL)encodeWithNewlines
{
    // Create a memory buffer which will contain the Base64 encoded string
    BIO * mem = BIO_new(BIO_s_mem());
    
    // Push on a Base64 filter so that writing to the buffer encodes the data
    BIO * b64 = BIO_new(BIO_f_base64());
    if (!encodeWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);
    
    // Encode all the data
    BIO_write(mem, [self bytes], [self length]);
    BIO_flush(mem);
    
    // Create a new string from the data in the memory buffer
    char * base64Pointer;
    long base64Length = BIO_get_mem_data(mem, &base64Pointer);
    NSString * base64String = [NSString stringWithCString:base64Pointer length:base64Length];
    
    // Clean up and go home
    BIO_free_all(mem);
    return base64String;
}

- (NSData *)my_decodeBase64
{
    return [self my_decodeBase64WithNewLines:YES];
}

- (NSData *)my_decodeBase64WithNewLines:(BOOL)encodedWithNewlines
{
    // Create a memory buffer containing Base64 encoded string data
    BIO * mem = BIO_new_mem_buf((void *) [self bytes], [self length]);
    
    // Push a Base64 filter so that reading from the buffer decodes it
    BIO * b64 = BIO_new(BIO_f_base64());
    if (!encodedWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);
    
    // Decode into an NSMutableData
    NSMutableData * data = [NSMutableData data];
    char inbuf[512];
    int inlen;
    while ((inlen = BIO_read(mem, inbuf, sizeof(inbuf))) > 0)
        [data appendBytes: inbuf length: inlen];
    
    // Clean up and go home
    BIO_free_all(mem);
    return data;
}


- (NSString *)my_hexString
{
    //  Adapted from SSCrypto.m by Ed Silva:
    //  Copyright (c) 2003-2006 Septicus Software. All rights reserved.
    const UInt8 *bytes = self.bytes;
    NSUInteger length = self.length;
    char out[2*length+1];
    char *dst = &out[0];
    for( NSUInteger i=0; i<length; i+=1 )
        dst += sprintf(dst,"%02X",*(bytes++));
    return [[[NSString alloc] initWithBytes: out length: 2*length encoding: NSASCIIStringEncoding]
            autorelease];
}

- (NSString *)my_hexDump
{
    //  Adapted from SSCrypto.m by Ed Silva:
    //  Copyright (c) 2003-2006 Septicus Software. All rights reserved.
    NSMutableString *ret=[NSMutableString stringWithCapacity:[self length]*2];
    /* dumps size bytes of *data to string. Looks like:
     * [0000] 75 6E 6B 6E 6F 77 6E 20
     *                  30 FF 00 00 00 00 39 00 unknown 0.....9.
     * (in a single line of course)
     */
    unsigned int size= [self length];
    const unsigned char *p = [self bytes];
    unsigned char c;
    unsigned int n;
    char bytestr[4] = {0};
    char addrstr[10] = {0};
    char hexstr[ 16*3 + 5] = {0};
    char charstr[16*1 + 5] = {0};
    for(n=1;n<=size;n++) {
        if (n%16 == 1) {
            /* store address for this line */
            snprintf(addrstr, sizeof(addrstr), "%.4x",
                     ((unsigned int)p-(unsigned int)self) );
        }
        
        c = *p;
        if (isalnum(c) == 0) {
            c = '.';
        }
        
        /* store hex str (for left side) */
        snprintf(bytestr, sizeof(bytestr), "%02X ", *p);
        strncat(hexstr, bytestr, sizeof(hexstr)-strlen(hexstr)-1);
        
        /* store char str (for right side) */
        snprintf(bytestr, sizeof(bytestr), "%c", c);
        strncat(charstr, bytestr, sizeof(charstr)-strlen(charstr)-1);
        
        if(n%16 == 0) {
            /* line completed */
            //printf("[%4.4s]   %-50.50s  %s\n", addrstr, hexstr, charstr);
            [ret appendString:[NSString stringWithFormat:@"[%4.4s]   %-50.50s  %s\n",
                               addrstr, hexstr, charstr]];
            hexstr[0] = 0;
            charstr[0] = 0;
        } else if(n%8 == 0) {
            /* half line: add whitespaces */
            strncat(hexstr, "  ", sizeof(hexstr)-strlen(hexstr)-1);
            strncat(charstr, " ", sizeof(charstr)-strlen(charstr)-1);
        }
        p++; /* next byte */
    }
    
    if (strlen(hexstr) > 0) {
        /* print rest of buffer if not empty */
        //printf("[%4.4s]   %-50.50s  %s\n", addrstr, hexstr, charstr);
        [ret appendString:[NSString stringWithFormat:@"[%4.4s]   %-50.50s  %s\n",
                           addrstr, hexstr, charstr]];
    }
    return ret;
}

@end


/*
 Copyright (c) 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
