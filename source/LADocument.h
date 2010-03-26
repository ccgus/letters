//
//  LADocument.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//


#import <Cocoa/Cocoa.h>
#import "LAAddressBookViewController.h"

@interface LADocument : NSDocument <LAAddressBookViewDelegate>{
    
    // FIXME: this should all probably go in a window controller subclass...
    
    IBOutlet NSProgressIndicator *progressIndicator;
	LAAddressBookViewController *addressBookVC;
}

@property (retain) NSString *toList;
@property (retain) NSString *fromList;
@property (retain) NSString *subject;
@property (retain) NSString *message;

@property (retain) NSString *statusMessage;

@property (retain) LAAddressBookViewController *addressBookVC;

- (IBAction)openAddressBookPicker:(id)sender;
- (void)addToAddress:(LAAddressBookEntry *)address;
@end
