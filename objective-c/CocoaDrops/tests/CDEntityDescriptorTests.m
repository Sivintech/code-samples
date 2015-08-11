//
//  CDEntityDescriptorTests.m
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/20/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "CDEntityDescriptorTests.h"
#import "TestEntities.h"
#import "CDEntityDescriptor.h"

@implementation CDEntityDescriptorTests

- (void)testBasic {
    STAssertTrueNoThrow([CDEntityDescriptor forClass:[SimpleTestEntity class]] != nil, nil);
    
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[SimpleTestEntity class]];
    STAssertEqualObjects(descriptor, [CDEntityDescriptor forClass:[SimpleTestEntity class]], @"Entity descriptors should be cached");
    
    STAssertEquals(descriptor.properties.count, (NSUInteger) 3, @"Entity descriptor should scan all properties");
    NSArray *expectedPropertiesInOrder = @[ @"stringProperty1", @"numberProperty", @"stringProperty2" ];
    STAssertTrue([descriptor.properties.allKeys isEqualToArray:expectedPropertiesInOrder], @"Entity descriptor should scan all properties maintaining order");
}

- (void)testComplaints {
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityNonIgnoredWeak class]], @"Entity descriptor should throw when weak properties are not ignored");
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityNonIgnoredReadonly class]], @"Entity descriptor should throw when readonly properties are not ignored");
    STAssertTrueNoThrow([CDEntityDescriptor forClass:[GoodEntity class]] != nil, @"Entity descriptor should not throw when all unsupported properties are explicitly ignored");
    
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityInvalidFix1 class]], @"Entity descriptor should throw when ignoring nonexistent property");
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityInvalidFix2 class]], @"Entity descriptor should throw when setting nonexistent property as identity");
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityInvalidFix3 class]], @"Entity descriptor should throw when setting nonexistent property as descriptive");
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityInvalidFix4 class]], @"Entity descriptor should throw when ignoring property which has some extra meaning");
}

- (void)testIgnoring {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[EntityWithIgnoredProperty class]];
    
    NSArray *referenceProperties = @[ @"property1", @"property3" ];
    STAssertTrue([descriptor.properties.allKeys isEqualToArray:referenceProperties], @"Entity descriptor should ignore usual properties on demand");
}

- (void)testContainedEntities {
    STAssertTrueNoThrow([CDEntityDescriptor forClass:[EntityWithGoodChildEntity class]] != nil, @"Entity descriptor should understand objects contained in properties");
    
    STAssertThrows([CDEntityDescriptor forClass:[EntityWithBadChildEntity class]], @"Entity descriptor should throw if contained object doesn't comply to descripting");
    
    STAssertTrueNoThrow([CDEntityDescriptor forClass:[EntityWithBadChildEntityIgnored class]] != nil, @"Entity descriptor should not throw if contained object doesn't comply to descripting but is ignored instead");
}

- (void)testContainedArrays {
    STAssertThrows([CDEntityDescriptor forClass:[BadEntityUnexplainedArray class]], @"Entity descriptor should throw when type for contained NSArray was not given in fixDescriptor");
    STAssertTrueNoThrow([CDEntityDescriptor forClass:[EntityWithArrayOfGoodEntities class]] != nil, @"Entity descriptor should not throw when type for contained NSArray was given");
    STAssertThrows([CDEntityDescriptor forClass:[EntityWithArrayOfBadEntities class]], @"Entity descriptor should throw when contained NSArray child type does not comply to descripting");
}

- (void)testSpecialTypes {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[EntityWithSpecialTypes class]];
    
    STAssertEquals([descriptor.properties[@"stringProperty"] kind], CDEntityPropertyString, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"stringProperty"] associatedType] == [NSString class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"integerProperty1"] kind], CDEntityPropertyNumeric, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"integerProperty1"] associatedType] == [NSNumber class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"integerProperty2"] kind], CDEntityPropertyNumeric, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"integerProperty2"] associatedType] == [NSNumber class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"floatProperty"] kind], CDEntityPropertyNumeric, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"floatProperty"] associatedType] == [NSNumber class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"doubleProperty"] kind], CDEntityPropertyNumeric, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"doubleProperty"] associatedType] == [NSNumber class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"dateProperty"] kind], CDEntityPropertyDate, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"dateProperty"] associatedType] == [NSDate class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"urlProperty"] kind], CDEntityPropertyUrl, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"urlProperty"] associatedType] == [NSURL class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"arrayProperty"] kind], CDEntityPropertyArray, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"arrayProperty"] associatedType] == [NSString class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"localeProperty"] kind], CDEntityPropertyLocale, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"localeProperty"] associatedType] == [NSLocale class], @"Entity descriptor should correctly recognize property types");
    
    STAssertEquals([descriptor.properties[@"referenceProperty"] kind], CDEntityPropertyReference, @"Entity descriptor should correctly recognize property types");
    STAssertTrue([descriptor.properties[@"referenceProperty"] associatedType] == [GoodEntity class], @"Entity descriptor should correctly recognize property types");
}

@end
