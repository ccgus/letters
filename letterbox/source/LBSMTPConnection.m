#import "LBSMTPConnection.h"
#import "TCP_Internal.h"
#import "LBAccount.h"
#import "IPAddress.h"
#import "LetterBoxUtilities.h"

@implementation LBSMTPConnection


- (id)initWithAccount:(LBAccount*)account {
    
    // FIXME: add a "smtp port" option
    IPAddress *addr = [IPAddress addressWithHostname:[account smtpServer] port:25];
    self = [self initToAddress:addr];
    
	if (self != nil) {
        
        if ([account imapTLS]) {
            
            NSMutableDictionary *sslProps = [NSMutableDictionary dictionary];
            
            [sslProps setObject:[NSNumber numberWithBool:YES] forKey:(id)kTCPPropertySSLAllowsAnyRoot];
            [sslProps setObject:[NSNull null] forKey:(id)kCFStreamSSLPeerName];
            [sslProps setObject:NSStreamSocketSecurityLevelTLSv1 forKey:(id)kCFStreamSSLLevel];
            
            [self setSSLProperties:sslProps];
        }
    }
    
    return self;
}




- (void) test {
    
    
    
}






@end
