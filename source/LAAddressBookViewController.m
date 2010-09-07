//
//  LAAddressBookViewController.m
//  Letters
//
//  Created by Samuel Goodwin on 3/25/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import "LAAddressBookViewController.h"
#import <AddressBook/AddressBook.h>

@implementation LAAddressBookEntry
@synthesize name, email;
-(id)initWithName:(NSString*)aname andEntry:(NSString*)anemail{
	if ((self = [super init])) {
		self.name = aname;
		self.email = anemail;
	}
	return self;
}
@end


@implementation LAAddressBookViewController
@synthesize peoplePicker, accessoryView, delegate;

+ (LAAddressBookViewController*)newAddressBookViewControllerWithDelegate:(id<LAAddressBookViewDelegate, NSObject>)aDelegate{
    
    LAAddressBookViewController *addressbookVC = [[LAAddressBookViewController alloc] initWithWindowNibName:@"LAAddressBookView"];
	addressbookVC.delegate = aDelegate;
    
    return [addressbookVC autorelease];
}

- (void)awakeFromNib{
	[self.peoplePicker setAccessoryView:self.accessoryView];
	self.peoplePicker.target = self;
	[self.peoplePicker setNameDoubleAction:@selector(to:)];
}

- (LAAddressBookEntry *)selectedEntry{
	NSString *email = nil;
	ABPerson *person = nil;
	
	NSArray *values = [self.peoplePicker selectedValues];
	if(!!values && [values count] > 0){
		email =  [values objectAtIndex:0];
	}
	values = nil;
	
	values = [self.peoplePicker selectedRecords];
	if(!!values && [values count] > 0){
		person = [values objectAtIndex:0];
	}
	NSString *personString = [[NSString alloc] initWithFormat:@"%@ %@", [person valueForProperty:kABFirstNameProperty], [person valueForProperty:kABLastNameProperty], nil];
	
	LAAddressBookEntry *entry = [[LAAddressBookEntry alloc] initWithName:personString andEntry:email];
	[personString release];
	
	NSLog(@"Sending entry: %@", entry);
	return entry;
}

- (IBAction)to:(id)sender{
	if(!!self.delegate && [self.delegate respondsToSelector:@selector(addToAddress:)]){
		[self.delegate addToAddress:[self selectedEntry]];
	}
}

- (IBAction)cc:(id)sender{
	if(!!self.delegate && [self.delegate respondsToSelector:@selector(addToAddress:)]){
		[self.delegate addToAddress:[self selectedEntry]];
	}
}

- (IBAction)bcc:(id)sender{
	if(!!self.delegate && [self.delegate respondsToSelector:@selector(addToAddress:)]){
		[self.delegate addToAddress:[self selectedEntry]];
	}
}

@end
