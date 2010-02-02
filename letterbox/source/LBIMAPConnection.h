#import <Foundation/Foundation.h>
#import "LBActivity.h"
#import "TCPConnection.h"
#import "TCPWriter.h"

@class LBIMAPReader;

typedef void (^LBResponseBlock)(NSError *);

@interface LBIMAPConnection : TCPConnection <TCPConnectionDelegate, LBActivity> {
    
    void (^responseBlock)(NSError *);
    
    NSInteger   commandCount;
    
    NSInteger   bytesRead;
    
    NSString    *currentCommand;
    
    NSInteger   currentFetchingMessageSize;
    NSString    *currentFetchingMessageHeader;
    
    NSString    *activityStatus;
}

@property (assign) BOOL debugOutput;
@property (retain) NSMutableData *responseBytes;
@property (assign) BOOL shouldCancelActivity;

- (void)connectUsingBlock:(LBResponseBlock)block;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password block:(LBResponseBlock)block;
- (void)canRead:(LBIMAPReader*)reader;
- (void)selectMailbox:(NSString*)mailbox block:(LBResponseBlock)block;
- (void)listMessagesWithBlock:(LBResponseBlock)block;
- (void)listSubscribedMailboxesWithBock:(LBResponseBlock)block;
- (void)logoutWithBlock:(LBResponseBlock)block;

- (void)createMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;
- (void)deleteMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;

- (void)subscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;
- (void)unsubscribeToMailbox:(NSString*)mailboxName withBlock:(LBResponseBlock)block;

- (void)fetchMessages:(NSString*)seqIds withBlock:(LBResponseBlock)block;

// this will parse the last LSUB command.  You better have done a listSubscribedMailboxesWithBock: right before this.
- (NSArray*)fetchedMailboxes;

- (NSArray*)searchedResultSet;

- (BOOL)isConnected;

- (void)setActivityStatusAndNotifiy:(NSString *)value;


@end
