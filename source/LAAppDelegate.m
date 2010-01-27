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
#import "LADocument.h"
#import <AddressBook/AddressBook.h>

@interface LAAppDelegate ()
- (void) connectToDefaultServerAndPullMail;
- (void) loadAccounts;
@end


@implementation LAAppDelegate
@synthesize mailViews;


+ (void)initialize {
    
    NSMutableDictionary *defaultValues  = [NSMutableDictionary dictionary];
    NSUserDefaults      *defaults       = [NSUserDefaults standardUserDefaults];
    
    
    // this will eventually be taken out.
    // Please don't mention it till @chockenberry has a chance to be surprised.
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    ABMultiValue *name = [[book me] valueForProperty:kABLastNameProperty];
    
    if ([[[name description] lowercaseString] rangeOfString:@"hockenberry"].location != NSNotFound) {
        [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"chocklock"];
    }
    
    [defaultValues setValue:@"~/Library/Letters/" forKey:@"cacheStoreFolder"];
    
    // other defaults would go here.
    
    [defaults registerDefaults:defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                           andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                         forEventClass:kInternetEventClass
                                                            andEventID:kAEGetURL];
        
        mailViews = [[NSMutableArray array] retain];
        accounts  = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc {
    [mailViews release];
    [accounts release];
    [prefsWindowController release];
    [super dealloc];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    #ifdef DEBUG
    
    if ([LAPrefs boolForKey:@"enableLogging"]) {
        LetterBoxEnableLogging();
    }
    
    if (NSRunAlertPanel(@"Start Over(ish)?", @"Should I clear out the cache and acct prefs?", @"Clear", @"Keep", nil)) {
        
        debug(@"deleting.");
        
        NSString *cacheLocation = [[LAPrefs stringForKey:@"cacheStoreFolder"] stringByExpandingTildeInPath];
        
        [[NSFileManager defaultManager] removeItemAtPath:cacheLocation error:nil];
        
        [LAPrefs setObject:nil forKey:@"accounts"];
    }
    
    #endif
    
    // get this guy started up.
    [[[LAActivityViewer sharedActivityViewer] window] orderFront:self];
    
    
    [self openNewMailView:nil];
    
    [self loadAccounts];
    
    if ([accounts count]) {
        [self connectToDefaultServerAndPullMail];
    }
    else {
        
        // OK, instead of having a fancy + button in the prefs where we load a new account template,
        // I'm just going to stick one on there, and only display one for now.  THIS IS TEMPORARY.
        
        LBAccount *account = [[LBAccount alloc] init];
        [accounts addObject:account];
        
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

- (void)loadAccounts {
    
    for (NSDictionary *d in [LAPrefs objectForKey:@"accounts"]) {
        
        assert([d isKindOfClass:[NSDictionary class]]);
        
        LBAccount *account = [LBAccount accountWithDictionary:d];
        
        [accounts addObject:account];
    }    
}

- (void)saveAccounts {
    
    NSMutableArray *accountsToSave = [NSMutableArray array];
    
    for (LBAccount *acct in accounts) {
        [accountsToSave addObject:[acct dictionaryRepresentation]];
    }
    
    [LAPrefs setObject:accountsToSave forKey:@"accounts"];
    
    [LAPrefs synchronize];
    
}

- (void)openNewMailView:(id)sender {
    LAMailViewController *mailView = [LAMailViewController openNewMailViewController];
    
    
    [mailView setWindowFrameAutosaveName:@"LAMailViewController"];
    [[mailView window] setFrameAutosaveName:@"LAMailViewController"];
    
    //[[mailView window] center];
    [[mailView window] makeKeyAndOrderFront:self];
    
    [mailViews addObject:mailView];
    
}

- (void)openPreferences:(id)sender {
    if (!prefsWindowController) {
        prefsWindowController = [[LAPrefsWindowController alloc] initWithWindowNibName:@"Prefs"];
        [[prefsWindowController window] center];
    }
    
    [[prefsWindowController window] makeKeyAndOrderFront:self];
}

- (void)pullTimerHit:(NSTimer*)t {
    
    for (LBAccount *acct in [self accounts]) {
        if ([acct isActive]) {
            [[acct server] checkForMail];
        }
    }
}

- (void)connectToDefaultServerAndPullMail {
    
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
    
    if (!periodicMailCheckTimer) {
        NSTimeInterval checkTimeInSeconds = 120; // FIMXE: hidden pref?
        
        periodicMailCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:checkTimeInSeconds
                                                                   target:self
                                                                 selector:@selector(pullTimerHit:)
                                                                 userInfo:nil
                                                                  repeats:YES] retain];
    }
    
}


- (NSArray *)accounts {
    return accounts;
}

- (NSDictionary*)parametersForQueryString:(NSString*)queryString {
    
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    NSArray* keyValuePairs = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString* pair in keyValuePairs) {
        NSArray* pieces = [pair componentsSeparatedByString:@"="];
        NSString* key   = [pieces objectAtIndex:0];
        NSString* value = [[pieces objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:value forKey:key];        
    }
    
    return params;
}

// mailto://test@test.com?subject=hello&body=nice+one
// mailto:test@test.com?subject=hello&body=nice+one

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    
    if ([event numberOfItems] == 2) {
        
        NSString* mailtoURL = [[event descriptorAtIndex:1] stringValue];
        
        if ([mailtoURL hasPrefix:@"mailto:"]) {
            
            // NSURL really likes it's //'s.
            if (![mailtoURL hasPrefix:@"mailto://"]) {
                mailtoURL = [NSString stringWithFormat:@"mailto://%@", [mailtoURL substringFromIndex:7]];
            }
            
            NSURL* urlForm = [NSURL URLWithString:mailtoURL];            
            
            // The user+host portion might actually contain multiple addresses, with user containing the 1st name and host containing everything else
            NSString* toAddresses = [[urlForm user] stringByAppendingString:[urlForm host]];
            
            // The rest of the parameters are in this dictionary
            NSDictionary* params = [self parametersForQueryString:[urlForm query]];
            
            NSDocumentController *dc = [NSDocumentController sharedDocumentController];
            NSError *err = nil;
            LADocument *doc = [dc openUntitledDocumentAndDisplay:YES error:&err];
            
            LBAccount *account = [[appDelegate accounts] lastObject];
            
            [doc setFromList:[account fromAddress]];
            [doc setToList:toAddresses];
            
            [doc setSubject:[params objectForKey:@"subject"]];
            [doc setMessage:[params objectForKey:@"body"]];
            
            [doc updateChangeCount:NSChangeDone];
        }
    }
}

@end
