//
//  LADocument.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//

#import "LADocument.h"
#import "LAAppDelegate.h"
#import <LetterBox/LetterBox.h>

@implementation LADocument
@synthesize statusMessage;
@synthesize toList;
@synthesize fromList;
@synthesize subject;
@synthesize message;
@synthesize addressBookVC;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [statusMessage release];
    [toList release];
    [fromList release];
    [subject release];
    [statusMessage release];
    
    [super dealloc];
}


- (NSString *)windowNibName {
    return @"LADocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    [self setFromList:[account fromAddress]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if (outError != NULL) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

- (void)sendMessage:(id)sender {
    
    // make the message binding do it's thing.
    // FIXME: is there a better way?  I'm sure there is...
    [[progressIndicator window] makeFirstResponder:nil];
    
    LBAccount *account = [[appDelegate accounts] lastObject];
    
    assert(account);
    
    if (![fromList length]) {
        [[fromTextField window] makeFirstResponder:fromTextField];
        return;
    }
    
    if (![toList length]) {
        [[toTextField window] makeFirstResponder:toTextField];
        return;
    }
    
    if (![subject length]) {
        [self setSubject:NSLocalizedString(@"No Subject", @"No Subject")];
        [[subjectTextField window] makeFirstResponder:subjectTextField];
        return;
    }
    
    if (![message length]) {
        [self setMessage:NSLocalizedString(@"This space intentionally left blank.", @"This space intentionally left blank.")];
        [[messageTextView window] makeFirstResponder:messageTextView];
        return;
    }
    
    LBMessage *lbmessage = [[[LBMessage alloc] init] autorelease];
    
    [lbmessage setTo:toList];
    [lbmessage setSender:fromList];
    [lbmessage setSubject:subject];
    [lbmessage setMessageBody:message];
    
    LBSMTPConnection *conn = [[[LBSMTPConnection alloc] initWithAccount:account] autorelease];
    
    conn.debugOutput = YES;
    
    [conn connectUsingBlock:^(NSError *err) {
        
        if (err) {
            NSRunAlertPanel(@"Error", [err localizedDescription], @"OK", nil, nil);
            return;
        }
        
        [conn sendMessage:lbmessage block:^(NSError *berr) {
            
            if (berr) {
                NSRunAlertPanel(@"Error", [berr localizedDescription], @"OK", nil, nil);
            }
            
            [self close];
            
            (void)lbmessage; // so it's kept alive by copyblock and friends till here.
            
        }];
    }];
}


#pragma mark -
#pragma mark Addressbook integration

- (IBAction)openAddressBookPicker:(id)sender{
	self.addressBookVC = [LAAddressBookViewController newAddressBookViewControllerWithDelegate:self];
	[self.addressBookVC showWindow:self];
	[[self.addressBookVC window] orderFront:self];
}

- (void)addToAddress:(LAAddressBookEntry *)address{
	[self willChangeValueForKey:@"toList"];
	if(!!self.toList){
		self.toList = [self.toList stringByAppendingFormat:@", %@", [address email]];
	}else{
		self.toList = [address email];
	}
	[self didChangeValueForKey:@"toList"];
}

@end
