//
//  TestEntities.m
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/20/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "TestEntities.h"
#import "CDEntityDescriptor.h"

@implementation SimpleTestEntity

@end


@implementation BadEntityNonIgnoredReadonly

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"weakProperty"];
}

@end


@implementation BadEntityUnexplainedArray

@end


@implementation BadEntityNonIgnoredWeak

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"readonlyProperty"];
}

@end


@implementation GoodEntity

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"weakProperty"];
    [descriptor ignoreProperty:@"readonlyProperty"];
}

@end


@implementation BadEntityInvalidFix1

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"nonexistentProperty"];
}

@end


@implementation BadEntityInvalidFix2

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setIdentityProperty:@"nonexistentProperty"];
}

@end


@implementation BadEntityInvalidFix3

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setDescriptiveProperties:@[ @"nonexistentProperty" ]];
}

@end


@implementation BadEntityInvalidFix4

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setIdentityProperty:@"stringProperty"];
    [descriptor ignoreProperty:@"stringProperty"];
}

@end


@implementation EntityWithIgnoredProperty

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"property2"];
}

@end


@implementation EntityWithGoodChildEntity

@end


@implementation EntityWithBadChildEntity

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[BadEntityNonIgnoredWeak class] forArrayProperty:@"property"];
}

@end


@implementation EntityWithBadChildEntityIgnored

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor ignoreProperty:@"property3"];
}

@end


@implementation EntityWithArrayOfGoodEntities

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[GoodEntity class] forArrayProperty:@"property"];
}

@end


@implementation EntityWithArrayOfBadEntities

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[BadEntityNonIgnoredWeak class] forArrayProperty:@"property"];
}

@end


@implementation EntityWithSpecialTypes

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[NSString class] forArrayProperty:@"arrayProperty"];
}

@end