//
//  MYAddressField.m
//  YourMove
//
//  Created by Jens Alfke on 7/16/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "MYAddressField.h"
#import "RegexKitLite.h"
#import <AddressBook/AddressBook.h>


@interface MYAddressField ()
@property (retain) MYAddressItem *selectedAddress;
@end


@implementation MYAddressField


@synthesize defaultAddresses=_defaultAddresses, addressProperty=_property, selectedAddress=_selectedAddress;


- (void) _computeAddresses
{
    NSMutableArray *newAddresses = $marray();
    if( _property ) {
        if( _prefix.length ) {
            // Find all the people in the address book matching _prefix:
            ABAddressBook *ab = [ABAddressBook sharedAddressBook];
            ABSearchElement *search = [ABPerson searchElementForProperty: _property
                                                                   label: nil
                                                                     key: nil
                                                                   value: nil
                                                              comparison: kABNotEqual];
            for( ABPerson *person in [ab recordsMatchingSearchElement: search] ) {
                ABMultiValue *values = [person valueForProperty: _property];
                NSString *first = [person valueForProperty: kABFirstNameProperty];
                NSString *last = [person valueForProperty: kABLastNameProperty];
                BOOL nameMatches = _prefix==nil || ([first.lowercaseString hasPrefix: _prefix] 
                                                    || [last.lowercaseString hasPrefix: _prefix]);
                for( int i=0; i<values.count; i++ ) {
                    NSString *address = [values valueAtIndex: i];
                    if( nameMatches || [address.lowercaseString hasPrefix: _prefix] ) {
                        MYAddressItem *item = [[MYAddressItem alloc] initWithPerson: person
                                                                        addressType: _property
                                                                            address: address];
                        [newAddresses addObject: item];
                        [item release];
                    }
                }
            }
        } else if( _defaultAddresses ) {
            [newAddresses addObjectsFromArray: _defaultAddresses];
        }
    }
    
    [newAddresses sortUsingSelector: @selector(compare:)];
    
    if( ifSetObj(&_addresses,newAddresses) )
        [self reloadData];
}

- (NSArray*) addresses
{
    if( ! _addresses )
        [self _computeAddresses];
    return _addresses;
}


- (void) awakeFromNib
{
    if( ! _addresses )
        _addresses = [[NSMutableArray alloc] init];
    _property = [kABEmailProperty retain];
    self.completes = NO;
    self.usesDataSource = YES;
    self.dataSource = self;
    self.delegate = self;
}

- (void) dealloc
{
    [_addresses release];
    [_property release];
    [_prefix release];
    [_selectedAddress release];
    [super dealloc];
}


- (BOOL) isExpanded
{
    id ax = NSAccessibilityUnignoredDescendant(self);
    return [[ax accessibilityAttributeValue: NSAccessibilityExpandedAttribute] boolValue];
}


- (void) setExpanded: (BOOL)expanded
{
    id ax = NSAccessibilityUnignoredDescendant(self);
    [ax accessibilitySetValue: $object(expanded) forAttribute: NSAccessibilityExpandedAttribute];
}


- (void) controlTextDidChange: (NSNotification*)n
{
    if( _prefix.length == 0 )
        self.expanded = YES;
    
    if( ifSetObj(&_prefix, self.stringValue.lowercaseString) )
        [self _computeAddresses];
    MYAddressItem *item = [[MYAddressItem alloc] initWithString: self.stringValue 
                                                    addressType: _property];
    self.selectedAddress = item;
    [item release];

    if( _prefix.length == 0 )
        self.expanded = NO;

    //Log(@"Address selection = %@",self.selectedAddress);
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    int sel = self.indexOfSelectedItem;
    self.selectedAddress = sel>=0 ?[self.addresses objectAtIndex: sel] :nil;
    //Log(@"Address selection = %@",self.selectedAddress);
}


#pragma mark -
#pragma mark DATA SOURCE:


- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return self.addresses.count;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [[self.addresses objectAtIndex: index] description];
}


@end




@implementation MYAddressItem

- (id) initWithName: (NSString*)name
        addressType: (NSString*)addressType address: (NSString*)address
{
    self = [super init];
    if( self ) {
        _name = name.length ?[name copy] :nil;
        _addressType = [addressType copy];
        _address = [address copy];
    }
    return self;
}
    
- (id) initWithPerson: (ABPerson*)person
          addressType: (NSString*)addressType address: (NSString*)address
{
    NSString *first = [person valueForProperty: kABFirstNameProperty] ?: @"";
    NSString *last = [person valueForProperty: kABLastNameProperty] ?: @"";
    NSString *name = $sprintf(@"%@ %@", first,last);
    
    self = [self initWithName: name addressType: addressType address: address];
    if( self )
        _uuid = person.uniqueId.copy;
    return self;
}

- (id) initWithString: (NSString*)str addressType: (NSString*)addressType
{
    #define kJustAddrRegex "[-a-zA-Z0-9%_+.]+(?:@[-a-zA-Z0-9.]+)"
    static NSString* const kNameAndAddrRegex = @"^\\s*(\\S+)?\\s*<("kJustAddrRegex")>\\s*$";
    static NSString* const kAddrRegex = @"^\\s*("kJustAddrRegex")\\s*$";

    NSString *name = nil;
    NSString *address = [str stringByMatching: kNameAndAddrRegex capture: 2];
    if( address ) {
        name = [str stringByMatching: kNameAndAddrRegex capture: 1];
    } else {
        address = [str stringByMatching: kAddrRegex];
    }
    if( ! address ) {
        [self release];
        return nil;
    }
    return [self initWithName: name addressType: addressType address: address];
}

@synthesize name=_name, addressType=_addressType, address=_address;

- (ABPerson*) person
{
    if( _uuid )
        return (ABPerson*) [[ABAddressBook sharedAddressBook] recordForUniqueId: _uuid];
    else
        return nil;
}

- (NSString*) description
{
    return $sprintf(@"%@%@<%@>", _name,(_name ?@" ":@""),_address);
}

- (NSComparisonResult) compare: (MYAddressItem*)other
{
    NSString *str1 = _name ?:_address;
    NSString *str2 = other->_name ?: other->_address;
    return [str1 localizedCaseInsensitiveCompare: str2];
}

@end
