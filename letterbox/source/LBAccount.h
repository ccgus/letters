#import <Foundation/Foundation.h>

@class LBServer;

@interface LBAccount : NSObject {
    LBServer *server;
}

+ (id) accountWithDictionary:(NSDictionary*)d;
- (NSDictionary*) dictionaryRepresentation;

@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSString *imapServer;
@property (retain) NSString *fromAddress;
@property (assign) int authType;
@property (assign) int imapPort;
@property (assign) BOOL imapTLS;
@property (retain) NSString *smtpServer;
@property (assign) BOOL isActive;

- (LBServer*)server;

@end
