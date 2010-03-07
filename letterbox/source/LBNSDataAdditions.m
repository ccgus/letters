//
//  LBNSDataAdditions.m
//  LetterBox
//
//  Created by August Mueller on 2/21/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LBNSDataAdditions.h"

#define CRLF "\r\n"

@implementation NSData (LetterBoxAdditions)

- (NSString*)lbSingleLineResponse {
    
    // *something* + crlf
    if ([self length] < 4) {
        return nil; 
    }
    
    const char *c = [self bytes];
    
    // check for completion of command.
    if (strncmp(&(c[[self length] - 2]), CRLF, 2)) {
        return nil;
    }
    
    // er... what about this char set?
    return [[[NSString alloc] initWithBytes:[self bytes] length:[self length] - 2 encoding:NSUTF8StringEncoding] autorelease];
}


- (BOOL)lbEndIsEqualTo:(NSString*)string; {
    
    if ([self length] < ([string length])) {
        return NO; 
    }
    
    const char *c = [self bytes];
    
    // check for completion of command.
    if (strncmp(&(c[[self length] - [string length]]), [string UTF8String], [string length])) {
        return NO;
    }
    
    return YES;
}

- (NSString*)lbLastLineOfMultiline {
    
    if ([self length] < 3) { // something + crlf
        return nil; 
    }
    
    NSUInteger len    = [self length];
    char *cdata       = (char *)[self bytes];
    NSUInteger idx    = len - 3;
    char *pos         = &cdata[idx];
    
    // if it doesn't end with crlf, it's bad.
    if (!(cdata[len - 1] == '\n' && cdata[len - 2] == '\r')) {
        return nil;
    }
    
    while (idx > 0) {
        // let's go backwards!
        
        if (*pos == '\n') {
            // get rid of the encountered lf, and the ending crlf
            NSRange r = NSMakeRange(idx + 1, len - (idx + 3));
            NSData *subData = [self subdataWithRange:r];
            NSString *junk = [[[NSString alloc] initWithBytes:[subData bytes] length:[subData length] encoding:NSUTF8StringEncoding] autorelease];
            return junk;
        }
        
        pos--;
        idx--;
    }
    
    return nil;
}

- (NSString*)lbFirstLine {
    
    if ([self length] < 3) { // something + crlf
        return nil; 
    }
    
    NSUInteger len    = [self length];
    NSUInteger idx    = 0;
    char *cdata       = (char *)[self bytes];
    
    while (idx < len) {
        
        if (cdata[idx] == '\r') {
            // get rid of the encountered lf, and the ending crlf
            NSRange r = NSMakeRange(0, idx);
            NSData *subData = [self subdataWithRange:r];
            NSString *junk = [[[NSString alloc] initWithBytes:[subData bytes] length:[subData length] encoding:NSUTF8StringEncoding] autorelease];
            return junk;
        }
        
        idx++;
    }
    
    return nil;
}

- (NSString*)utf8String {
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
}






















#define Assert(Cond) if (!(Cond)) abort()

int fbsd_b64_pton(char const *src, u_char *target, size_t targsize);
int fbsd_b64_ntop(u_char const *src, size_t srclength, char *target, size_t targsize);

static char gEncodingTable[ 64 ] = {
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
};

static const char Base64[] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char Pad64 = '=';




- (NSString*) base64Encoding {
    
    int targetsize = ((float)[self length] * 1.35); // it's a 3/4 ratio ... right?
    
    char *target = malloc(targetsize);
    
    fbsd_b64_ntop([self bytes], [self length], target, targetsize);
    
    NSString *s = [NSString stringWithUTF8String:target];
    
    free(target);
    
    return s;
}


+ (NSData*) dataWithBase64EncodedString:(NSString*)base64String {
    
    const char *c   = [base64String UTF8String];
    int len64       = strlen(c);
    
    u_char *mdata   = malloc(len64);
    
    int actualLen   = fbsd_b64_pton(c, mdata, len64);
    
    if (actualLen == -1) {
        return nil;
    }
    
    NSData *d       = [NSData dataWithBytes:mdata length:actualLen];
    
    free(mdata);
    
    return d;
}



@end



int fbsd_b64_ntop(u_char const *src, size_t srclength, char *target, size_t targsize) {
	size_t datalength = 0;
	u_char input[3];
	u_char output[4];
	size_t i;
    
	while (2 < srclength) {
		input[0] = *src++;
		input[1] = *src++;
		input[2] = *src++;
		srclength -= 3;
        
		output[0] = input[0] >> 2;
		output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
		output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
		output[3] = input[2] & 0x3f;
		Assert(output[0] < 64);
		Assert(output[1] < 64);
		Assert(output[2] < 64);
		Assert(output[3] < 64);
        
		if (datalength + 4 > targsize)
			return (-1);
		target[datalength++] = Base64[output[0]];
		target[datalength++] = Base64[output[1]];
		target[datalength++] = Base64[output[2]];
		target[datalength++] = Base64[output[3]];
	}
    
	/* Now we worry about padding. */
	if (0 != srclength) {
		/* Get what's left. */
		input[0] = input[1] = input[2] = '\0';
		for (i = 0; i < srclength; i++)
			input[i] = *src++;
        
		output[0] = input[0] >> 2;
		output[1] = ((input[0] & 0x03) << 4) + (input[1] >> 4);
		output[2] = ((input[1] & 0x0f) << 2) + (input[2] >> 6);
		Assert(output[0] < 64);
		Assert(output[1] < 64);
		Assert(output[2] < 64);
        
		if (datalength + 4 > targsize)
			return (-1);
		target[datalength++] = Base64[output[0]];
		target[datalength++] = Base64[output[1]];
		if (srclength == 1)
			target[datalength++] = Pad64;
		else
			target[datalength++] = Base64[output[2]];
		target[datalength++] = Pad64;
	}
	if (datalength >= targsize)
		return (-1);
	target[datalength] = '\0';	/* Returned value doesn't count \0. */
	return (datalength);
}


int fbsd_b64_pton(char const *src, u_char *target, size_t targsize)
{
	int tarindex, state, ch;
	char *pos;
    
	state = 0;
	tarindex = 0;
    
	while ((ch = *src++) != '\0') {
		if (isspace((unsigned char)ch))        /* Skip whitespace anywhere. */
			continue;
        
		if (ch == Pad64)
			break;
        
		pos = strchr(Base64, ch);
		if (pos == 0) 		/* A non-base64 character. */
			return (-1);
        
		switch (state) {
            case 0:
                if (target) {
                    if ((size_t)tarindex >= targsize)
                        return (-1);
                    target[tarindex] = (pos - Base64) << 2;
                }
                state = 1;
                break;
            case 1:
                if (target) {
                    if ((size_t)tarindex + 1 >= targsize)
                        return (-1);
                    target[tarindex]   |=  (pos - Base64) >> 4;
                    target[tarindex+1]  = ((pos - Base64) & 0x0f)
                    << 4 ;
                }
                tarindex++;
                state = 2;
                break;
            case 2:
                if (target) {
                    if ((size_t)tarindex + 1 >= targsize)
                        return (-1);
                    target[tarindex]   |=  (pos - Base64) >> 2;
                    target[tarindex+1]  = ((pos - Base64) & 0x03)
                    << 6;
                }
                tarindex++;
                state = 3;
                break;
            case 3:
                if (target) {
                    if ((size_t)tarindex >= targsize)
                        return (-1);
                    target[tarindex] |= (pos - Base64);
                }
                tarindex++;
                state = 0;
                break;
            default:
                abort();
		}
	}
    
	/*
	 * We are done decoding Base-64 chars.  Let's see if we ended
	 * on a byte boundary, and/or with erroneous trailing characters.
	 */
    
	if (ch == Pad64) {		/* We got a pad char. */
		ch = *src++;		/* Skip it, get next. */
		switch (state) {
            case 0:		/* Invalid = in first position */
            case 1:		/* Invalid = in second position */
                return (-1);
                
            case 2:		/* Valid, means one byte of info */
                /* Skip any number of spaces. */
                for ((void)NULL; ch != '\0'; ch = *src++)
                    if (!isspace((unsigned char)ch))
                        break;
                /* Make sure there is another trailing = sign. */
                if (ch != Pad64)
                    return (-1);
                ch = *src++;		/* Skip the = */
                /* Fall through to "single trailing =" case. */
                /* FALLTHROUGH */
                
            case 3:		/* Valid, means two bytes of info */
                /*
                 * We know this char is an =.  Is there anything but
                 * whitespace after it?
                 */
                for ((void)NULL; ch != '\0'; ch = *src++)
                    if (!isspace((unsigned char)ch))
                        return (-1);
                
                /*
                 * Now make sure for cases 2 and 3 that the "extra"
                 * bits that slopped past the last full byte were
                 * zeros.  If we don't check them, they become a
                 * subliminal channel.
                 */
                if (target && target[tarindex] != 0)
                    return (-1);
		}
	} else {
		/*
		 * We ended by seeing the end of the string.  Make sure we
		 * have no partial bytes lying around.
		 */
		if (state != 0)
			return (-1);
	}
    
    return (tarindex);
}











