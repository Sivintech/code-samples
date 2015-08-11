//
// Created by Arseni Buinitsky
//

#import "CDEntityDescriptor.h"
#import "objc/runtime.h"

#import <CocoaDrops/CocoaDrops.h>

static NSString *EntitiesCacheLock = @"Hello, Cache!";
static NSCache *EntitiesCache = nil;


#define RequiredByDefault NO


@implementation CDEntityProperty

- (id)initWithName:(NSString *)name kind:(CDEntityPropertyKind)kind associatedType:(Class)associatedType required:(BOOL)required {
    self = [super init];
    if (self) {
        _name = [name copy];
        _kind = kind;
        _associatedType = associatedType;
        _required = required;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@/%@]", self.name, NSStringFromClass(self.associatedType)];
}

@end


@interface CDEntityDescriptor ()

- (void)introspectProperties:(Class)_entityClass toDictionary:(NSMutableDictionary *)dictionary withIgnoredSet:(NSMutableSet *)ignoredSet;

- (BOOL)class:(Class)sibling isKindOfClass:(Class)ancestor;
- (BOOL)associatedTypeSupported:(Class)type;

@end


@implementation CDEntityDescriptor {
@private
    NSMutableDictionary *_properties;
    NSMutableSet *_unsupportedProperties;
}

#pragma mark - Lifecycle and configuration

- (id)initWithClass:(Class)entityClass {
    return [CDEntityDescriptor forClass:entityClass];
}

+ (CDEntityDescriptor *)forClass:(Class)entityClass {
    @synchronized (EntitiesCacheLock) {
        if (EntitiesCache == nil) {
            EntitiesCache = [NSCache new];
        }
        NSString *cacheKey = NSStringFromClass(entityClass);
        CDEntityDescriptor *description = [EntitiesCache objectForKey:cacheKey];

        if (description) {
            return description;
        } else {
            description = [[CDEntityDescriptor alloc] init];
            if (description) {
                description->_entityClass = entityClass;
                description->_properties = [CDOrderedMutableDictionary dictionaryWithCapacity:16];
                description->_unsupportedProperties = [NSMutableSet setWithCapacity:8];

                Class _class = entityClass;
                
                while (_class && _class != [NSObject class]) {
                    [description introspectProperties:_class
                                         toDictionary:description->_properties
                                       withIgnoredSet:description->_unsupportedProperties];
                    
                    _class = class_getSuperclass(_class);
                }
                

                _class = entityClass;
                while (_class && _class != [NSObject class]) {
                    if ([_class respondsToSelector:@selector(fixEntityDescriptor:)]) {
                        [_class performSelector:@selector(fixEntityDescriptor:) withObject:description];
                    }
                    
                    _class = class_getSuperclass(_class);
                }

                if (description->_unsupportedProperties.count) {
                    [NSException raise:@"Unsupported properties for CDEntityDescriptor"
                                format:@"Properties %@ are unsupported in entity class %@; you should manually ignore them to remove this exception",
                                 description->_unsupportedProperties, entityClass];
                }

                for (CDEntityProperty *property in description->_properties.allValues) {
                    if (property.kind == CDEntityPropertyArray && !property.associatedType) {
                        [NSException raise:@"Array properties need associated types for CDEntityDescriptor"
                                    format:@"Array property %@ in entity class %@ need an associated type", property.name, entityClass];
                    }
                }

                [EntitiesCache setObject:description forKey:cacheKey];
            }

            return description;
        }
    }
}

- (NSDictionary *)properties {
    return _properties;
}

#pragma mark - Introspection

- (void)introspectProperties:(Class)entityClass toDictionary:(NSMutableDictionary *)dictionary withIgnoredSet:(NSMutableSet *)ignoredSet {
    unsigned int outCount = 0;
    objc_property_t *list = class_copyPropertyList(entityClass, &outCount);

    // iterate over entity properties
    for (unsigned int i = 0; i < outCount; ++i) {
        NSString *name = [NSString stringWithCString:property_getName(list[i]) encoding:NSASCIIStringEncoding];
        NSString *attributes = [NSString stringWithCString:property_getAttributes(list[i]) encoding:NSASCIIStringEncoding];

        BOOL considerStrong = NO,
                considerReadonly = NO,
                considerReference = NO,
                considerNumeric = NO,
                considerArray = NO,
                considerString = NO,
                considerUrl = NO,
                considerDate = NO,
                considerLocale = NO;
        Class referenceType = NULL;

        // parse attributes string
        for (NSString *token in [attributes componentsSeparatedByString:@","]) {
            if ([token hasPrefix:@"V"] || [token isEqualToString:@"D"] || [token isEqualToString:@"N"]) { // field name or @dynamic marker or nonatomic
                // ignore
            } else if ([token hasPrefix:@"T"]) { // type
                NSString *typeCode = [token substringFromIndex:1];
                if ([typeCode hasPrefix:@"@"] && typeCode.length > 3) {
                    typeCode = [typeCode substringWithRange:NSMakeRange(2, typeCode.length - 3)];
                    Class associatedClass = objc_getClass([typeCode cStringUsingEncoding:NSASCIIStringEncoding]);

                    if (!associatedClass) {
                        [NSException raise:@"Unsupported property type in CDEntityDescriptor"
                                    format:@"Unsupported property %@ with attributes string [%@] in %@ (cannot resolve class %@)",
                                     name, attributes, entityClass, typeCode];
                    }

                    if ([self class:associatedClass isKindOfClass:[NSArray class]]) {
                        considerArray = YES;
                    } else if ([self class:associatedClass isKindOfClass:[NSString class]]) {
                        considerString = YES;
                    } else if ([self class:associatedClass isKindOfClass:[NSDate class]]) {
                        considerDate = YES;
                    } else if ([self class:associatedClass isKindOfClass:[NSNumber class]]) {
                        considerNumeric = YES;
                    } else if ([self class:associatedClass isKindOfClass:[NSURL class]]) {
                        considerUrl = YES;
                    } else if ([self class:associatedClass isKindOfClass:[NSLocale class]]) {
                        considerLocale = YES;
                    } else {
                        considerReference = YES;
                        referenceType = associatedClass;
                    }
                } else {
                    if ([@[ @"c", @"i", @"s", @"l", @"q", @"C", @"I", @"S", @"L", @"Q", @"f", @"d", @"B"] containsObject:typeCode]) {
                        considerStrong = YES;
                        considerNumeric = YES;
                    } else {
                        [NSException raise:@"Unsupported property type in CDEntityDescriptor"
                                    format:@"Unsupported property %@ with attributes string [%@] in %@", name, attributes, entityClass];
                    }
                }
            } else if ([token isEqualToString:@"W"]) { // weak
                considerReadonly = YES;
            } else if ([token isEqualToString:@"R"]) { // readonly
                considerReadonly = YES;
            } else if ([token isEqualToString:@"&"]) { // strong or retain
                considerStrong = YES;
            } else if ([token isEqualToString:@"C"]) { // copy
                considerStrong = YES;
            } else {
                [NSException raise:@"Unsupported property type in CDEntityDescriptor"
                            format:@"Unsupported property %@ with attributes string [%@] in %@", name, attributes, entityClass];
            }
        }

        // validate stuff and register property
        CDEntityPropertyKind kind = (CDEntityPropertyKind) 0;
        
        if (considerReadonly || !considerStrong) {
            [ignoredSet addObject:name];
            continue;
        } else if (considerReference) {
            if (![self associatedTypeSupported:referenceType]) {
                [ignoredSet addObject:name];
                continue;
            } else {
                kind = CDEntityPropertyReference;
            }
        } else if (considerNumeric) {
            kind = CDEntityPropertyNumeric;
            referenceType = [NSNumber class];
        } else if (considerArray) {
            kind = CDEntityPropertyArray;
        } else if (considerString) {
            kind = CDEntityPropertyString;
            referenceType = [NSString class];
        } else if (considerDate) {
            kind = CDEntityPropertyDate;
            referenceType = [NSDate class];
        } else if (considerUrl) {
            kind = CDEntityPropertyUrl;
            referenceType = [NSURL class];
        } else if (considerLocale) {
            kind = CDEntityPropertyLocale;
            referenceType = [NSLocale class];
        } else {
            NSAssert(NO, @"CDEntityDescriptor logic failure");
        }

        CDEntityProperty *property = [[CDEntityProperty alloc]
                                      initWithName:name kind:kind associatedType:referenceType required:RequiredByDefault];
        dictionary[name] = property;
    }

    free(list);
}

#pragma mark - Fixing

- (void)ignoreProperty:(NSString *)propertyName {
    if ([_unsupportedProperties containsObject:propertyName]) {
        [_unsupportedProperties removeObject:propertyName];
    } else if (_properties[propertyName] != nil) {
        if ([self.descriptiveProperties containsObject:propertyName]) {
            [NSException raise:@"Cannot ignore property in CDEntityDescriptor" format:@"Property %@ is in descriptive properties list", propertyName];
        } else if ([self.identityProperties containsObject:propertyName]) {
            [NSException raise:@"Cannot ignore property in CDEntityDescriptor" format:@"Property %@ is in identity properties list", propertyName];
        }
        [_properties removeObjectForKey:propertyName];
    } else {
        [NSException raise:@"Cannot ignore property in CDEntityDescriptor" format:@"Property %@ was not detected in %@",
            propertyName, NSStringFromClass(self.entityClass)];
    }
}

- (void)setContainedType:(Class)type forArrayProperty:(NSString *)propertyName {
    CDEntityProperty *property = _properties[propertyName];
    if (property && property.kind == CDEntityPropertyArray) {
        if ([self associatedTypeSupported:type]) {
            CDEntityProperty *newProperty = [[CDEntityProperty alloc]
                                                               initWithName:propertyName kind:CDEntityPropertyArray associatedType:type required:property.required];
            _properties[propertyName] = newProperty;
        } else {
            [NSException raise:@"Cannot set contained type in CDEntityDescriptor"
                        format:@"Contained typed %@ is not supported (property %@ of %@)", type, propertyName, NSStringFromClass(self.entityClass)];
        }
    } else {
        [NSException raise:@"Cannot set contained type in CDEntityDescriptor"
                    format:@"Property %@ was not detected in %@ or is not an array", propertyName, NSStringFromClass(self.entityClass)];
    }
}

- (void)require:(BOOL)require property:(NSString *)propertyName {
    CDEntityProperty *property = _properties[propertyName];
    if (property) {
        CDEntityProperty *newProperty = [[CDEntityProperty alloc]
                                         initWithName:propertyName kind:property.kind associatedType:property.associatedType required:require];
        _properties[propertyName] = newProperty;
    } else {
        [NSException raise:@"Cannot require property in CDEntityDescriptor"
                    format:@"Property %@ was not detected in %@", propertyName, NSStringFromClass(self.entityClass)];
    }
}

- (void)setIdentityProperty:(NSString *)propertyName {
    if (propertyName) {
        [self setIdentityProperties:@[ propertyName ]];
    } else {
        [self setIdentityProperties:nil];
    }
}

- (void)setIdentityProperties:(NSArray *)propertyNames {
    if (propertyNames.count) {
        for (NSString *propertyName in propertyNames) {
            if (_properties[propertyName] == nil) {
                [NSException raise:@"Cannot set identity properties in CDEntityDescriptor"
                            format:@"Property %@ was not detected in %@", propertyName, NSStringFromClass(self.entityClass)];
            }
        }
        _identityProperties = [propertyNames copy];
    } else {
        _identityProperties = nil;
    }
}

- (void)setDescriptiveProperties:(NSArray *)propertyNames {
    if (propertyNames.count) {
        for (NSString *propertyName in propertyNames) {
            if (_properties[propertyName] == nil) {
                [NSException raise:@"Cannot set descriptive properties in CDEntityDescriptor"
                            format:@"Property %@ was not detected in %@", propertyName, NSStringFromClass(self.entityClass)];
            }
        }
        _descriptiveProperties = [propertyNames copy];
    } else {
        _descriptiveProperties = nil;
    }
}

#pragma mark - Util

- (BOOL)class:(Class)sibling isKindOfClass:(Class)ancestor {
    while (sibling) {
        if (sibling == ancestor) {
            return YES;
        }
        sibling = class_getSuperclass(sibling);
    }
    return NO;
}

- (BOOL)associatedTypeSupported:(Class)type {
    if (type == NULL) {
        return NO;
    }
    
    BOOL basic = [self class:type isKindOfClass:[NSString class]]
        || [self class:type isKindOfClass:[NSDate class]]
        || [self class:type isKindOfClass:[NSURL class]]
        || [self class:type isKindOfClass:[NSNumber class]]
        || [self class:type isKindOfClass:[NSLocale class]];
    
    if (!basic) {
        @try {
            [CDEntityDescriptor forClass:type];
        }
        @catch (NSException *exception) {
            return NO;
        }
    }
    
    return YES;
}


@end