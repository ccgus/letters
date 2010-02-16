#import <Foundation/Foundation.h>
#import "LBActivity.h"
#import "LBTCPConnection.h"

@class LBAccount;

@interface LBSMTPConnection : LBTCPConnection  {

}

- (void)test;
- (id)initWithAccount:(LBAccount*)account;

@end
