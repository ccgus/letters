//
//  LAAppDelegate.m
//  Letters
//
//  Created by August Mueller on 1/19/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "LAAppDelegate.h"
#import "LAMailViewController.h"
#import "LAActivityViewer.h"
#import <AddressBook/AddressBook.h>

@interface LAAppDelegate ()
- (void) connectToDefaultServerAndPullMail;
- (void) loadAccounts;
@end


@implementation LAAppDelegate
@synthesize mailViews=_mailViews;


+ (void) initialize {
    
	NSMutableDictionary *defaultValues 	= [NSMutableDictionary dictionary];
    NSUserDefaults      *defaults 	 	= [NSUserDefaults standardUserDefaults];
    
    
    // this will eventually be taken out.
    // Please don't mention it till @chockenberry has a chance to be surprised.
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    ABMultiValue *name = [[book me] valueForProperty:kABLastNameProperty];
    
    if ([[[name description] lowercaseString] rangeOfString:@"hockenberry"].location != NSNotFound) {
        [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"chocklock"];
    }
    
    // other defaults would go here.
    
    [defaults registerDefaults:defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}

- (id) init {
	self = [super init];
	if (self != nil) {
        _mailViews = [[NSMutableArray array] retain];
        _accounts  = [[NSMutableArray array] retain];
	}
	return self;
}

- (void)dealloc {
    [_mailViews release];
    [_accounts release];
    [_prefsWindowController release];
    [super dealloc];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    #ifdef DEBUG
    
    if (NSRunAlertPanel(@"Start Over(ish)?", @"Should I clear out the cache and acct prefs?", @"Clear", @"Keep", nil)) {
        
        debug(@"deleting.");
        
        NSString *path = [@"~/Library/Letters/" stringByExpandingTildeInPath];
        
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        [LAPrefs setObject:nil forKey:@"accounts"];
    }
    
    #endif
    
    // get this guy started up.
    [[[LAActivityViewer sharedActivityViewer] window] orderFront:self];
    
    
    [self openNewMailView:nil];
    
    [self loadAccounts];
    
    if ([_accounts count]) {
        [self connectToDefaultServerAndPullMail];
    }
    else {
        
        // OK, instead of having a fancy + button in the prefs where we load a new account template,
        // I'm just going to stick one on there, and only display one for now.  THIS IS TEMPORARY.
        
        LBAccount *account = [[LBAccount alloc] init];
        [_accounts addObject:account];
        
        if ([[LAPrefs stringForKey:@"iToolsMember"] length] > 0) {
            account.imapServer      = @"mail.me.com";
            account.imapPort        = 993;
            account.username        = [LAPrefs stringForKey:@"iToolsMember"];
            account.connectionType  = CONNECTION_TYPE_TLS;
            account.authType        = IMAP_AUTH_TYPE_PLAIN;
            
            
            // FIXME: need to setup some preferred smtp servers here.
            account.smtpServer      = @"smtp.me.com";
            
        }
        
        [self saveAccounts];
        
        [self openPreferences:self];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NewAccountCreated"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *arg1) {
                                                      [self connectToDefaultServerAndPullMail];
                                                  }];
}

- (void) loadAccounts {
    
    for (NSDictionary *d in [LAPrefs objectForKey:@"accounts"]) {
        
        assert([d isKindOfClass:[NSDictionary class]]);
        
        LBAccount *account = [LBAccount accountWithDictionary:d];
        
        [_accounts addObject:account];
    }    
}

- (void) saveAccounts {
    
    NSMutableArray *accountsToSave = [NSMutableArray array];
    
    for (LBAccount *acct in _accounts) {
        [accountsToSave addObject:[acct dictionaryRepresentation]];
    }
    
    [LAPrefs setObject:accountsToSave forKey:@"accounts"];
    
    [LAPrefs synchronize];
    
}

- (void) openNewMailView:(id)sender {
    LAMailViewController *mailView = [LAMailViewController openNewMailViewController];
    
    [[mailView window] center];
    [[mailView window] makeKeyAndOrderFront:self];
    
    [_mailViews addObject:mailView];
    
}

- (void) openPreferences:(id)sender {
    if (!_prefsWindowController) {
        _prefsWindowController = [[LAPrefsWindowController alloc] initWithWindowNibName:@"Prefs"];
        [[_prefsWindowController window] center];
    }
    
    [[_prefsWindowController window] makeKeyAndOrderFront:self];
}

- (void) pullTimerHit:(NSTimer*)t {
    
    for (LBAccount *acct in [self accounts]) {
        if ([acct isActive]) {
            [[acct server] checkForMail];
        }
    }
}

- (void) connectToDefaultServerAndPullMail {
    
    for (LBAccount *acct in [self accounts]) {
        
        // FIXME: this is going to have to be temporary, till we get a UI to turn it on/ off
        [acct setIsActive:YES];
        
        if ([acct isActive]) {
            
            [[acct server] connectUsingBlock:^(BOOL success, NSError *error) {
                
                if (!success) {
                    // FIXME: show a warning or something?
                    NSLog(@"error: %@", error);
                }
                else {
                    [[acct server] checkForMail];
                }
            
            }];
        }
    }
    
    if (!_periodicMailCheckTimer) {
        NSTimeInterval checkTimeInSeconds = 120; // FIMXE: hidden pref?
        
        _periodicMailCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:checkTimeInSeconds
                                                                    target:self
                                                                  selector:@selector(pullTimerHit:)
                                                                  userInfo:nil
                                                                   repeats:YES] retain];
    }
    
}


- (NSArray *)accounts {
    return _accounts;
}

@end
