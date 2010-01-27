//
//  LADocument.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//


#import <Cocoa/Cocoa.h>

@interface LADocument : NSDocument {
    
    // FIXME: this should all probably go in a window controller subclass...
    
    IBOutlet NSProgressIndicator *progressIndicator;
}

@property (retain) NSString *toList;
@property (retain) NSString *fromList;
@property (retain) NSString *subject;
@property (retain) NSString *message;

@property (retain) NSString *statusMessage;

@end
