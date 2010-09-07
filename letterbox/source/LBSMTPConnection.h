#import <Foundation/Foundation.h>
#import "LBActivity.h"
#import "LBTCPConnection.h"

@class LBAccount;

@interface LBSMTPConnection : LBTCPConnection  {

}

//- (void)test;
- (id)initWithAccount:(LBAccount*)account;

- (void)sendMessage:(LBMessage*)message block:(LBResponseBlock)block;

@end
