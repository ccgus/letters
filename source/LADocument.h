//
//  LADocument.h
//  Letters
//
//  Created by August Mueller on 1/19/10.
//


#import <Cocoa/Cocoa.h>

@interface LADocument : NSDocument {
    
    // FIXME: this should all probably go in a window controller subclass...
    IBOutlet NSTextField *toField;
    IBOutlet NSTextField *fromField;
    IBOutlet NSTextField *subjectField;
    
    IBOutlet NSTextView  *messageView;
    
    IBOutlet NSProgressIndicator *progressIndicator;
    
    NSString *_statusMessage;
}

@property (retain) NSString *statusMessage;

@end
