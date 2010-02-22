#import "LBAccount.h"
#import "LBServer.h"

@implementation LBAccount

@synthesize username;
@synthesize password;
@synthesize imapServer;
@synthesize fromAddress;
@synthesize authType;
@synthesize imapPort;
@synthesize imapTLS;
@synthesize smtpServer;
@synthesize isActive;

- (id) init {
	self = [super init];
	if (self != nil) {
		imapPort = 993;
	}
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [username release];
    [password release];
    [imapServer release];
    [smtpServer release];
    [fromAddress release];
    
    [super dealloc];
}

- (LBServer*) server {
    
    if (!server) {
        
        NSString *cacheFolder = [@"~/Library/Letters/" stringByExpandingTildeInPath];
        
        server = [[LBServer alloc] initWithAccount:self usingCacheFolder:[NSURL fileURLWithPath:cacheFolder isDirectory:YES]];
    }
    
    return server;
}


+ (id) accountWithDictionary:(NSDictionary*)d {
    
    LBAccount *acct = [[[self alloc] init] autorelease];
    
    if ([d objectForKey:@"username"]) {
        acct.username = [d objectForKey:@"username"];
    }
    
    if ([d objectForKey:@"password"]) {
        acct.password = [d objectForKey:@"password"];
    }
    
    if ([d objectForKey:@"imapServer"]) {
        acct.imapServer = [d objectForKey:@"imapServer"];
    }
    
    if ([d objectForKey:@"fromAddress"]) {
        acct.fromAddress = [d objectForKey:@"fromAddress"];
    }
    
    if ([d objectForKey:@"authType"]) {
        acct.authType = [[d objectForKey:@"authType"] intValue];
    }
    
    if ([d objectForKey:@"imapPort"]) {
        acct.imapPort = [[d objectForKey:@"imapPort"] intValue];
    }
    
    if ([d objectForKey:@"isActive"]) {
        acct.isActive = [[d objectForKey:@"isActive"] boolValue];
    }
    
    if ([d objectForKey:@"imapTLS"]) {
        acct.imapTLS = [[d objectForKey:@"imapTLS"] boolValue];
    }
    
    if ([d objectForKey:@"smtpServer"]) {
        acct.smtpServer = [d objectForKey:@"smtpServer"];
    }
    
    return acct;
}

- (NSDictionary*) dictionaryRepresentation {

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    [d setObject:username ? username : @"" forKey:@"username"];
    [d setObject:password ? password : @"" forKey:@"password"];
    
    [d setObject:fromAddress ? fromAddress : @"" forKey:@"fromAddress"];
    
    [d setObject:imapServer ? imapServer : @""     forKey:@"imapServer"];
    [d setObject:[NSNumber numberWithInt:imapPort] forKey:@"imapPort"];
    
    [d setObject:smtpServer ? smtpServer : @"" forKey:@"smtpServer"];
    
    [d setObject:[NSNumber numberWithInt:authType] forKey:@"authType"];
    [d setObject:[NSNumber numberWithBool:isActive] forKey:@"isActive"];
    
    [d setObject:[NSNumber numberWithBool:imapTLS] forKey:@"imapTLS"];
    
    return d;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"%@ (%@@%@)", [super description], username, imapServer];
}

@end
