//
//  BLIPEchoClient.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Adapted from Apple sample code "CocoaEcho":
//  http://developer.apple.com/samplecode/CocoaEcho/index.html
//

#import <Cocoa/Cocoa.h>
#import "BLIPConnection.h"
@class MYBonjourBrowser;


@interface BLIPEchoClient : NSObject <BLIPConnectionDelegate>
{
    IBOutlet NSTextField * inputField;
    IBOutlet NSTextField * responseField;
    IBOutlet NSTableView * serverTableView;
    
    MYBonjourBrowser * _serviceBrowser;
    BLIPConnection *_connection;
}

@property (readonly) MYBonjourBrowser *serviceBrowser;
@property (readonly) NSArray *serviceList;

- (IBAction)serverClicked:(id)sender;
- (IBAction)sendText:(id)sender;

@end
