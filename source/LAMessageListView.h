//
//  LAMessageListView.h
//  Letters
//
//  Created by August Mueller on 2/20/10.
//  Copyright 2010 Letters App. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LAMessageListView : NSTableView {
    
}

@end

@interface NSObject (LAMessageListViewAdditions)
- (BOOL)tableViewDidRecieveDeleteKey:(NSTableView*)tableView;
- (BOOL)tableViewDidRecieveEnterOrSpaceKey:(NSTableView*)tableView;
@end
