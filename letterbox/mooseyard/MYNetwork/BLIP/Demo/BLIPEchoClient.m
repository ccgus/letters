//
//  BLIPEchoClient.m
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//  Adapted from Apple sample code "CocoaEcho":
//  http://developer.apple.com/samplecode/CocoaEcho/index.html
//

#import "BLIPEchoClient.h"
#import "MYBonjourBrowser.h"
#import "MYBonjourService.h"
#import "CollectionUtils.h"
#import "MYNetwork.h"
#import "Target.h"


@implementation BLIPEchoClient


- (void)awakeFromNib 
{
    [self.serviceBrowser start];
}

- (MYBonjourBrowser*) serviceBrowser {
    if (!_serviceBrowser)
        _serviceBrowser = [[MYBonjourBrowser alloc] initWithServiceType: @"_blipecho._tcp."];
    return _serviceBrowser;
}

- (NSArray*) serviceList {
    return [_serviceBrowser.services.allObjects sortedArrayUsingSelector: @selector(compare:)];
}

+ (NSArray*) keyPathsForValuesAffectingServiceList {
    return $array(@"serviceBrowser.services");
}


#pragma mark -
#pragma mark BLIPConnection support

/* Opens a BLIP connection to the given address. */
- (void)openConnection: (MYBonjourService*)service 
{
    _connection = [[BLIPConnection alloc] initToBonjourService: service];
    if( _connection ) {
        _connection.delegate = self;
        [_connection open];
    } else
        NSBeep();
}

/* Closes the currently open BLIP connection. */
- (void)closeConnection
{
    [_connection close];
}

/** Called after the connection successfully opens. */
- (void) connectionDidOpen: (TCPConnection*)connection {
    if (connection==_connection) {
        [inputField setEnabled: YES];
        [responseField setEnabled: YES];
        [inputField.window makeFirstResponder: inputField];
    }
}

/** Called after the connection fails to open due to an error. */
- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error {
    [serverTableView.window presentError: error];
}

/** Called after the connection closes. */
- (void) connectionDidClose: (TCPConnection*)connection {
    if (connection==_connection) {
        if (connection.error)
            [serverTableView.window presentError: connection.error];
        [_connection release];
        _connection = nil;
        [inputField setEnabled: NO];
        [responseField setEnabled: NO];
    }
}


#pragma mark -
#pragma mark GUI action methods

- (IBAction)serverClicked:(id)sender {
    NSTableView * table = (NSTableView *)sender;
    int selectedRow = [table selectedRow];
    
    [self closeConnection];
    if (-1 != selectedRow)
        [self openConnection: [self.serviceList objectAtIndex:selectedRow]];
}

/* Send a BLIP request containing the string in the textfield */
- (IBAction)sendText:(id)sender 
{
    BLIPRequest *r = [_connection request];
    r.bodyString = [sender stringValue];
    BLIPResponse *response = [r send];
    if (response) {
        response.onComplete = $target(self,gotResponse:);
        [inputField setStringValue: @""];
    } else
        NSBeep();
}

/* Receive the response to the BLIP request, and put its contents into the response field */
- (void) gotResponse: (BLIPResponse*)response
{
    [responseField setObjectValue: response.bodyString];
}    


@end

int main(int argc, char *argv[])
{
    //RunTestCases(argc,(const char**)argv);
    return NSApplicationMain(argc,  (const char **) argv);
}
