//
//  With.h
//  MYUtilities
//
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define WITH(OBJ)       id __with=[OBJ beginWith]; @try

#define ENDWITH         @finally{[__with endWith];}
#define CATCHWITH       @catch(NSException *x){id w=__with; __with=nil; _catchWith(w,x);} @finally{[__with endWith];}

void _catchWith( id with, NSException *x );

@interface NSAutoreleasePool (With)
+ (NSAutoreleasePool*) beginWith;
- (void) endWith;
@end