//
//  MYAddressField.h
//  YourMove
//
//  Created by Jens Alfke on 7/16/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MYAddressItem, ABPerson;


@interface MYAddressField : NSComboBox
{
    NSString *_property, *_prefix;
    NSMutableArray *_addresses;
    NSArray *_defaultAddresses;
    MYAddressItem *_selectedAddress;
}

@property (getter=isExpanded) BOOL expanded;

@property (copy) NSString *addressProperty;
@property (copy) NSArray *defaultAddresses;

@property (readonly,retain) MYAddressItem* selectedAddress;

@end



@interface MYAddressItem : NSObject
{
    NSString *_name, *_addressType, *_address, *_uuid;
}
- (id) initWithName: (NSString*)name
        addressType: (NSString*)addressType address: (NSString*)address;
- (id) initWithPerson: (ABPerson*)person
          addressType: (NSString*)addressType address: (NSString*)address;
- (id) initWithString: (NSString*)str addressType: (NSString*)addressType;
@property (readonly) NSString *name, *addressType, *address;
@property (readonly) ABPerson *person;
@end