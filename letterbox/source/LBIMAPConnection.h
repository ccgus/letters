#import <Foundation/Foundation.h>
#import "LBActivity.h"
#import "LBTCPConnection.h"

@class LBAccount;

@interface LBIMAPConnection : LBTCPConnection {
    
    NSInteger   commandCount;
    
    NSInteger   currentFetchingMessageSize;
    NSString    *currentFetchingMessageHeader;
}

- (id)initWithAccount:(LBAccount*)account;

- (void)loginWithUsername:(NSString *)username password:(NSString *)password block:(LBResponseBlock)block;
- (void)selectMailbox:(NSString*)mailbox block:(LBResponseBlock)block;
- (void)listMessagesWithBlock:(LBResponseBlock)block;
- (void)listSubscribedMailboxesWithBock:(LBResponseBlock)block;
- (void)logoutWithBlock:(LBResponseBlock)block;

- (void)createMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;
- (void)deleteMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;

- (void)subscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;
- (void)unsubscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;

- (void)fetchMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block;
- (void)deleteMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block;

- (void)idleWithBlock:(LBResponseBlock)block;

// this will parse the last LSUB command.  You better have done a listSubscribedMailboxesWithBock: right before this.
- (NSArray*)fetchedMailboxes;

- (NSArray*)searchedResultSet;

- (NSData*)lastFetchedMessage;


@end
