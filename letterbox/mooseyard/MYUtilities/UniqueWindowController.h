//
//  UniqueWindowController.h
//  MYUtilities
//
//  Created by Jens Alfke on 3/14/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UniqueWindowController : NSWindowController

+ (UniqueWindowController*) instanceWith: (id)model;
+ (UniqueWindowController*) openWith: (id)model;

+ (BOOL) isModel: (id)model1 equalToModel: (id)model2;

- (void) reopenWith: (id)model;

@end


@interface UniqueWindowController (Abstract)

- (id) initWith: (id)model;
@property (readonly) id model;

@end