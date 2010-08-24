//
//  LBMIMEGenerator.h
//  LetterBox
//
//  Created by Alex Morega on 2010-04-12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LBMIMEMessage.h"


// E-mail (RFC 2822) message generator
@interface LBMIMEGenerator : NSObject

// Traverse |message| and generate an encoded email message.
+ (NSString*)stringFromMessage:(LBMIMEMessage*)message;

@end
