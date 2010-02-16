#import <Foundation/Foundation.h>
#import "LBActivity.h"
#import "LBTCPConnection.h"

@class LBAccount;

@interface LBSMTPConnection : LBTCPConnection <TCPConnectionDelegate, LBActivity> {

}

- (void) test;
- (id)initWithAccount:(LBAccount*)account;

- (void)helloWithBlock:(LBResponseBlock)block;

@end
