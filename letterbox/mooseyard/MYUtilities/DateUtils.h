//
//  DateUtils.h
//  MYUtilities
//
//  Created by Jens Alfke on 3/25/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    
    /** Absolute time (since 'reference date') to NSDate. 0.0 -> nil. */
    NSDate* $date( CFAbsoluteTime );
    
    /** NSDate to absolute time (since 'reference date'). nil -> 0.0 */
    CFAbsoluteTime $time( NSDate* );

    
    NSTimeInterval TimeIntervalSinceBoot(void);


#ifdef __cplusplus
}
#endif
