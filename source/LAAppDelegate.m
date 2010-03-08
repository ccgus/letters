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
#import "LAPrefsWindowController.h"
#import <LetterBox/LetterBox.h>

#import <AddressBook/AddressBook.h>

@interface LAAppDelegate ()
- (void)connectToDefaultServerAndPullMail;
- (void)loadAccounts;
- (void)scheduleMailCheckTimer;
@end


@implementation LAAppDelegate
@synthesize mailViews;


+ (void)initialize {
    
    NSMutableDictionary *defaultValues  = [NSMutableDictionary dictionary];
    NSUserDefaults      *defaults       = LAPrefs;
    
    
    // this will eventually be taken out.
    // Please don't mention it till @chockenberry has a chance to be surprised.
    ABAddressBook *book = [ABAddressBook sharedAddressBook];
    ABMultiValue *name = [[book me] valueForProperty:kABLastNameProperty];
    
    if ([[[name description] lowercaseString] rangeOfString:@"hockenberry"].location != NSNotFound) {
        [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"chocklock"];
    }
    
    [defaultValues setValue:@"~/Library/Letters/" forKey:@"cacheStoreFolder"];
    [defaultValues setValue:[NSNumber numberWithDouble:2] forKey:@"mailAutoCheckTimeIntervalInMinutes"];
    
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
    [super dealloc];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    #ifdef xDEBUG
    
    // defaults write com.lettersapp.CrashyEmailApp enableLogging 1
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
    
    
    [self loadAccounts];
    
    if (![accounts count]) {
        [self openPreferences:self selectModuleWithId:@"LAPrefsAccountsModule"];
    }
    
    [self openNewMailView:nil];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NewAccountCreated"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *arg1) {
                                                      [self connectToDefaultServerAndPullMail];
                                                  }];
    
    // Observe changes in the mail check timer interval
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:@"mailAutoCheckTimeIntervalInMinutes"
                                               options:0
                                               context:NULL];
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
    [[LAPrefsWindowController sharedController] showWindow:sender];
}

- (void)openPreferences:(id)sender selectModuleWithId:(NSString *)moduleId {
    LAPrefsWindowController *prefsCtrl = [LAPrefsWindowController sharedController];
    [prefsCtrl selectModuleWithIdentifier:moduleId];
    [prefsCtrl showWindow:sender];
}

- (void)pullTimerHit:(NSTimer*)t {
    
    for (LBAccount *acct in [self accounts]) {
        if ([acct isActive]) {
            [[acct server] checkForMail];
        }
    }
}

- (void)checkForMail:(id)sender {
    [self pullTimerHit:nil];
}

- (void)connectToDefaultServerAndPullMail {
    
    for (LBAccount *acct in [self accounts]) {
        
        // FIXME: this is going to have to be temporary, till we get a UI to turn it on/ off
        [acct setIsActive:YES];
        
        if ([acct isActive]) {
            
            [[acct server] connectUsingBlock:^(NSError *error) {
                
                if (error) {
                    // FIXME: show a warning or something?
                    NSLog(@"error: %@", error);
                }
                else {
                    //[[acct server] checkForMail];
                }
            
            }];
        }
    }
    
    // turning this off for now, since it's a bit annoying right now when debugging stuff.
    //[self scheduleMailCheckTimer];
}

- (void)scheduleMailCheckTimer {
    
    // If the check time is zero, the user wants to check manually
    NSTimeInterval checkTimeInMinutes = [LAPrefs doubleForKey:@"mailAutoCheckTimeIntervalInMinutes"];
    //NSLog (@"Scheduling to %0.2f", checkTimeInMinutes);
    
    // Remove any existing timer
    [periodicMailCheckTimer invalidate];
    [periodicMailCheckTimer release];
    periodicMailCheckTimer = nil;
    
    // An interval of zero means the user wants to check manually
    if (checkTimeInMinutes > 0) {
        periodicMailCheckTimer = [[NSTimer scheduledTimerWithTimeInterval:checkTimeInMinutes * 60.0f
                                                                   target:self
                                                                 selector:@selector(pullTimerHit:)
                                                                 userInfo:nil
                                                                  repeats:YES] retain];
    }
}

- (NSArray *)accounts {
    return accounts;
}

- (void)addAccount {
    [accounts addObject:[[[LBAccount alloc] init] autorelease]];
}

- (void)removeAccount:(NSInteger)index {
    [accounts removeObjectAtIndex:index];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"mailAutoCheckTimeIntervalInMinutes"]) {
        [self scheduleMailCheckTimer];
    }
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

- (void) debugAction:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    //LBSMTPConnection *smtp = [[LBSMTPConnection alloc] initWithAccount:[[self accounts] lastObject]];
    //[smtp test];
    
    
}


@end
