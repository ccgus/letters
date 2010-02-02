//
//  BLIPEchoServer.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLIPConnection.h"

@interface BLIPEchoServer : NSObject <TCPListenerDelegate, BLIPConnectionDelegate>
{
    BLIPListener *_listener;
}

@end
