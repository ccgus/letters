//
//  BLIP_Internal.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/10/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "BLIPConnection.h"
#import "BLIPRequest.h"
#import "BLIPProperties.h"
@class BLIPWriter;


/* Private declarations and APIs for BLIP implementation. Not for use by clients! */


/* BLIP message types; encoded in each frame's header. */
typedef enum {
    kBLIP_MSG,                      // initiating message
    kBLIP_RPY,                      // response to a MSG
    kBLIP_ERR                       // error response to a MSG
} BLIPMessageType;

/* Flag bits in a BLIP frame header */
enum {
    kBLIP_TypeMask  = 0x000F,       // bits reserved for storing message type
    kBLIP_Compressed= 0x0010,       // data is gzipped
    kBLIP_Urgent    = 0x0020,       // please send sooner/faster
    kBLIP_NoReply   = 0x0040,       // no RPY needed
    kBLIP_MoreComing= 0x0080,       // More frames coming (Applies only to individual frame)
    kBLIP_Meta      = 0x0100,       // Special message type, handled internally (hello, bye, ...)
};
typedef UInt16 BLIPMessageFlags;


/** Header of a BLIP frame as sent across the wire. All fields are big-endian. */
typedef struct {
    UInt32           magic;         // magic number (kBLIPFrameHeaderMagicNumber)
    UInt32           number;        // serial number of MSG
    BLIPMessageFlags flags;         // encodes frame type, "more" flag, and other delivery options
    UInt16           size;          // total size of frame, _including_ this header
} BLIPFrameHeader;

#define kBLIPFrameHeaderMagicNumber 0x9B34F206

#define kBLIPProfile_Hi  @"Hi"      // Used for Profile header in meta greeting message
#define kBLIPProfile_Bye @"Bye"     // Used for Profile header in meta close-request message


@interface BLIPConnection ()
- (void) _dispatchRequest: (BLIPRequest*)request;
- (void) _dispatchResponse: (BLIPResponse*)response;
@end


@interface BLIPMessage ()
@property BOOL sent, propertiesAvailable, complete;
- (BLIPMessageFlags) _flags;
- (void) _setFlag: (BLIPMessageFlags)flag value: (BOOL)value;
- (void) _encode;
@end


@interface BLIPMessage ()
- (id) _initWithConnection: (BLIPConnection*)connection
                    isMine: (BOOL)isMine
                     flags: (BLIPMessageFlags)flags
                    number: (UInt32)msgNo
                      body: (NSData*)body;
- (BOOL) _writeFrameTo: (BLIPWriter*)writer maxSize: (UInt16)maxSize;
@property (readonly) SInt32 _bytesWritten;
- (void) _assignedNumber: (UInt32)number;
- (BOOL) _receivedFrameWithHeader: (const BLIPFrameHeader*)header body: (NSData*)body;
- (void) _connectionClosed;
@end


@interface BLIPRequest ()
- (id) _initWithConnection: (BLIPConnection*)connection
                      body: (NSData*)body 
                properties: (NSDictionary*)properties;
@end


@interface BLIPResponse ()
- (id) _initWithRequest: (BLIPRequest*)request;
@end
