//
//  LAAddressBookViewController.h
//  Letters
//
//  Created by Samuel Goodwin on 3/25/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/ABPeoplePickerView.h>

@protocol LAAddressBookViewDelegate;

@interface LAAddressBookViewController : NSWindowController {
	ABPeoplePickerView *peoplePicker;
	NSView *accessoryView;
	id<LAAddressBookViewDelegate, NSObject> delegate;
}
@property(nonatomic, retain) IBOutlet ABPeoplePickerView *peoplePicker;
@property(nonatomic, retain) IBOutlet NSView *accessoryView;
@property(nonatomic, assign) IBOutlet id<LAAddressBookViewDelegate, NSObject> delegate;

+ (LAAddressBookViewController*)newAddressBookViewControllerWithDelegate:(id<LAAddressBookViewDelegate, NSObject>)aDelegate;
- (NSString *)selectedString;
- (IBAction)to:(id)sender;
- (IBAction)cc:(id)sender;
- (IBAction)bcc:(id)sender;
@end

@protocol LAAddressBookViewDelegate
- (void)addToAddress:(NSString *)address;

@optional
- (void)addCcAddress:(NSString*)address;
- (void)addBccAddress:(NSString*)address;
@end