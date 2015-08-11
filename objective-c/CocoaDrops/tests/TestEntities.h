//
//  TestEntities.h
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/20/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface SimpleTestEntity : NSObject

@property NSString *stringProperty1;
@property NSNumber *numberProperty;
@property NSString *stringProperty2;

@end


@interface BadEntityNonIgnoredWeak : NSObject

@property NSString *stringProperty;

@property (weak) NSString *weakProperty;
@property (readonly) NSString *readonlyProperty;

@end


@interface BadEntityNonIgnoredReadonly : NSObject

@property NSString *stringProperty;

@property (weak) NSString *weakProperty;
@property (readonly) NSString *readonlyProperty;

@end


@interface BadEntityUnexplainedArray : NSObject

@property NSArray *property;

@end


@interface GoodEntity : NSObject

@property NSString *stringProperty;

@property (weak) NSString *weakProperty;
@property (readonly) NSString *readonlyProperty;

@end


@interface BadEntityInvalidFix1 : NSObject

@property NSString *stringProperty;
@property NSNumber *numberProperty;

@end


@interface BadEntityInvalidFix2 : NSObject

@property NSString *stringProperty;
@property NSNumber *numberProperty;

@end


@interface BadEntityInvalidFix3 : NSObject

@property NSString *stringProperty;
@property NSNumber *numberProperty;

@end


@interface BadEntityInvalidFix4 : NSObject

@property NSString *stringProperty;
@property NSNumber *numberProperty;

@end


@interface EntityWithIgnoredProperty : NSObject

@property NSString *property1;
@property NSString *property2;
@property NSString *property3;

@end


@interface EntityWithGoodChildEntity : NSObject

@property NSString *property1;
@property NSNumber *property2;
@property GoodEntity *property3;

@end


@interface EntityWithBadChildEntity : NSObject

@property NSString *property1;
@property NSNumber *property2;
@property BadEntityInvalidFix1 *property3;

@end


@interface EntityWithBadChildEntityIgnored : NSObject

@property NSString *property1;
@property NSNumber *property2;
@property BadEntityInvalidFix1 *property3;

@end


@interface EntityWithArrayOfGoodEntities : NSObject

@property NSArray *property;

@end


@interface EntityWithArrayOfBadEntities : NSObject

@property NSArray *property;

@end


@interface EntityWithSpecialTypes : NSObject

@property NSString *stringProperty;

@property NSUInteger integerProperty1;
@property int integerProperty2;
@property float floatProperty;
@property double doubleProperty;

@property NSDate *dateProperty;

@property NSURL *urlProperty;

@property NSArray *arrayProperty;

@property NSLocale *localeProperty;

@property GoodEntity *referenceProperty;

@end