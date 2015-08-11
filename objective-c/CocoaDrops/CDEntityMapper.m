//
// Created by Arseni Buinitsky
//

#import "CDEntityMapper.h"

@implementation CDEntityValueConverter
@synthesize mapper, unmapper, inputType, outputType;

- (id)initWithInputType:(Class)_inputType outputType:(Class)_outputType mapperBlock:(CDMapperBlock)_mapper unmapperBlock:(CDUnmapperBlock)_unmapper {
    self = [self init];
    if (self) {
        inputType = _inputType;
        outputType = _outputType;
        mapper = _mapper;
        unmapper = _unmapper;
    }
    return self;
}


- (id)map:(id)object {
    id mappedObject = [NSNull null];

    if (object == [NSNull null]) {
        object = nil;
    }

    if (object && ![object isKindOfClass:self.inputType]) {
        CDLog(@"[WARN]: MLEntityValueConverter: input object is of type %@ instead of expected %@",
                NSStringFromClass([object class]), NSStringFromClass(self.inputType));
    } else {
        id mappedObjectTmp = self.mapper(object);
        if (mappedObjectTmp != nil && mappedObjectTmp != [NSNull null]) {
            if (![mappedObjectTmp isKindOfClass:self.outputType]) {
                CDLog(@"[WARN]: MLEntityValueConverter: mapper error: mapped object is of type %@ instead of expected %@",
                        NSStringFromClass([mappedObjectTmp class]), NSStringFromClass(self.outputType));
            } else {
                mappedObject = mappedObjectTmp;
            }
        }
    }

    return mappedObject;
}

- (id)unmap:(id)object {
    id unmappedObject = [NSNull null];

    if (object == [NSNull null]) {
        object = nil;
    }

    if (object && ![object isKindOfClass:self.outputType]) {
        CDLog(@"[WARN]: MLEntityValueConverter: unmapping input object is of type %@ instead of expected %@",
                NSStringFromClass([object class]), NSStringFromClass(self.outputType));
    } else {
        id unmappedObjectTmp = self.unmapper(object);
        if (unmappedObjectTmp != nil && unmappedObjectTmp != [NSNull null]) {
            if (![unmappedObjectTmp isKindOfClass:self.inputType]) {
                CDLog(@"[WARN]: MLEntityValueConverter: mapper error: unmapped object is of type %@ instead of expected %@",
                        NSStringFromClass([unmappedObjectTmp class]), NSStringFromClass(self.inputType));
            } else {
                unmappedObject = unmappedObjectTmp;
            }
        }
    }

    return unmappedObject;
}

@end


@implementation CDEntityPropertyMapping
@synthesize originalName, mappedName, mappingProvider, required;

@end


@interface CDEntityMapper ()

- (NSUInteger)indexOfPropertyForName:(NSString *)propertyName;

- (void)addPropertyName:(NSString *)name kind:(CDEntityPropertyKind)kind associatedType:(Class)associatedType required:(BOOL)required;
- (void)addChildMappingProvider:(id<CDMappingProvider>)mappingProvider;

+ (CDEntityValueConverter *)urlConverter;
+ (CDEntityValueConverter *)localeConverter;
+ (CDEntityValueConverter *)passConverterForNumber;
+ (CDEntityValueConverter *)passConverterForString;

@end


@implementation CDEntityMapper {
    NSMutableArray *mappings;
    NSMutableDictionary *childMappers;
}
@synthesize inputType, outputType;

#pragma mark - Creation

- (id)init {
    self = [super init];
    if (self) {
        mappings = [NSMutableArray arrayWithCapacity:16];
        childMappers = [NSMutableDictionary dictionaryWithCapacity:8];

        [self addChildMappingProvider:[CDEntityMapper passConverterForNumber]];
        [self addChildMappingProvider:[CDEntityMapper passConverterForString]];
        [self addChildMappingProvider:[CDEntityMapper converterForDateInYyyymmdd]];
        [self addChildMappingProvider:[CDEntityMapper localeConverter]];
        [self addChildMappingProvider:[CDEntityMapper urlConverter]];
    }
    return self;
}

+ (CDEntityMapper *)forClass:(Class)entityClass {
    return [self forClass:entityClass withChildMappingProviders:@[]];
}

+ (CDEntityMapper *)forClass:(Class)entityClass withChildMappingProvider:(id <CDMappingProvider>)childProvider {
    return [self forClass:entityClass withChildMappingProviders:@[ childProvider ]];
}

+ (CDEntityMapper *)forClass:(Class)entityClass withChildMappingProviders:(NSArray *)childProviders {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:entityClass];
    CDEntityMapper *mapper = [[CDEntityMapper alloc] init];
    mapper->inputType = entityClass;
    mapper->outputType = [NSDictionary class];

    for (id<CDMappingProvider> provider in childProviders) {
        [mapper addChildMappingProvider:provider];
    }

    for (CDEntityProperty *property in descriptor.properties.allValues) {
        [mapper addPropertyName:property.name kind:property.kind associatedType:property.associatedType required:property.required];
    }

    return mapper;
}


#pragma mark - Mapping

- (id)map:(id)object {
    if (object == nil || object == [NSNull null]) {
        return [NSNull null];
    }

    if (![object isKindOfClass:self.inputType]) {
        CDLog(@"[WARN]: MLEntityMapper: input object is of type %@ instead of expected %@",
                NSStringFromClass([object class]), NSStringFromClass(self.inputType));
        return [NSNull null];
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:mappings.count];

    for (CDEntityPropertyMapping *map in mappings) {
        id value = [object valueForKey:map.originalName];
        id mappedValue = [NSNull null];

        if (value != nil && value != [NSNull null]) {
            id mappedValueTmp;

            if (![value isKindOfClass:map.mappingProvider.inputType]) {
                CDLog(@"[WARN]: MLEntityMapper: property %@ is of type %@ instead of expected %@",
                        map.originalName, NSStringFromClass([value class]), NSStringFromClass(map.mappingProvider.inputType));
            } else {
                mappedValueTmp = [map.mappingProvider map:value];
                if (mappedValueTmp != nil && mappedValueTmp != [NSNull null]) {
                    if (![mappedValueTmp isKindOfClass:map.mappingProvider.outputType]) {
                        CDLog(@"[WARN]: MLEntityMapper: converter error: property %@ mapped into type %@ instead of expected %@",
                                map.originalName, NSStringFromClass([mappedValueTmp class]), NSStringFromClass(map.mappingProvider.outputType));
                    } else {
                        mappedValue = mappedValueTmp;
                    }
                }
            }
        }

        [dictionary setObject:mappedValue forKey:map.mappedName];
    }

    if (self.postMapBlock) {
        self.postMapBlock(dictionary, object);
    }

    return dictionary;
}

- (id)unmap:(id)object {
    if (object == nil || object == [NSNull null]) {
        return nil;
    }

    if (![object isKindOfClass:self.outputType]) {
        CDLog(@"[WARN]: MLEntityMapper: unmapping input object is of type %@ instead of expected %@",
                NSStringFromClass([object class]), NSStringFromClass(self.outputType));
        return nil;
    }

    id entity = [[self.inputType alloc] init];
    if (!entity) {
        CDLog(@"[WARN]: MLEntityMapper: unable to instantiate %@ while unmaping", NSStringFromClass(self.inputType));
        return nil;
    }

    for (CDEntityPropertyMapping *map in mappings) {
        id value = [object valueForKeyPath:map.mappedName];
        id unmappedValue = nil;

        if (value != nil && value != [NSNull null]) {
            id unmappedValueTmp;

            if (![value isKindOfClass:map.mappingProvider.outputType]) {
                CDLog(@"[WARN]: MLEntityMapper: unmapping property %@ (original name is %@) is of type %@ instead of expected %@",
                        map.mappedName, map.originalName, NSStringFromClass([value class]), NSStringFromClass(map.mappingProvider.outputType));
            } else {
                unmappedValueTmp = [map.mappingProvider unmap:value];
                if (unmappedValueTmp != nil && unmappedValueTmp != [NSNull null]) {
                    if (![unmappedValueTmp isKindOfClass:map.mappingProvider.inputType]) {
                        CDLog(@"[WARN]: MLEntityMapper: converter error: property %@ (original name is %@) unmapped into type %@ instead of expected %@",
                                map.mappedName, map.originalName, NSStringFromClass([unmappedValueTmp class]), NSStringFromClass(map.mappingProvider.inputType));
                    } else {
                        unmappedValue = unmappedValueTmp;
                    }
                }
            }
        }

        [entity setValue:unmappedValue forKey:map.originalName];
    }

    if (self.postUnmapBlock) {
        self.postUnmapBlock(object, entity);
    }

    return entity;
}

#pragma mark - Mapping manipulation

- (void)addPropertyName:(NSString *)name kind:(CDEntityPropertyKind)kind associatedType:(Class)associatedType required:(BOOL)required {
    NSAssert([self indexOfPropertyForName:name] == NSNotFound, @"MLEntityMapper: cannot add property %@: already exists", name);

    CDEntityPropertyMapping *map = [[CDEntityPropertyMapping alloc] init];
    map.originalName = name;
    map.mappedName = name;
    map.mappingProvider = [self mappingProviderForPropertyKind:kind associatedType:associatedType];
    map.required = required;

    [mappings addObject:map];
}

- (void)resetRequiredFlag:(BOOL)required forProperty:(NSString *)propertyName {
    NSUInteger index = [self indexOfPropertyForName:propertyName];
    NSAssert(index != NSNotFound, @"MLEntityMapper: cannot update property %@ on %@: property not found", propertyName, NSStringFromClass(self.inputType));

    CDEntityPropertyMapping *map = [mappings objectAtIndex:index];
    map.required = required;
}

- (void)resetMappingProvider:(id <CDMappingProvider>)mappingProvider forProperty:(NSString *)propertyName {
    NSUInteger index = [self indexOfPropertyForName:propertyName];
    NSAssert(index != NSNotFound, @"MLEntityMapper: cannot update property %@ on %@: property not found", propertyName, NSStringFromClass(self.inputType));

    CDEntityPropertyMapping *map = [mappings objectAtIndex:index];

    if (map.mappingProvider.inputType != mappingProvider.inputType) {
        [NSException raise:@"MLEntityMapper: invalid reset mapping provider"
                    format:@"New mapping provider for property %@ has %@ input type instead of previous %@",
                     propertyName, NSStringFromClass(map.mappingProvider.inputType), NSStringFromClass(mappingProvider.inputType)];
    }
    map.mappingProvider = mappingProvider;
}

- (void)resetMappedName:(NSString *)mappedName forProperty:(NSString *)propertyName {
    NSUInteger index = [self indexOfPropertyForName:propertyName];
    NSAssert(index != NSNotFound, @"MLEntityMapper: cannot update property %@ on %@: property not found", propertyName, NSStringFromClass(self.inputType));

    CDEntityPropertyMapping *map = [mappings objectAtIndex:index];
    map.mappedName = mappedName;
}

#pragma mark - Utils

- (NSUInteger)indexOfPropertyForName:(NSString *)propertyName {
    for (NSUInteger index = 0; index < mappings.count; ++index) {
        CDEntityPropertyMapping *map = [mappings objectAtIndex:index];
        if ([map.originalName isEqualToString:propertyName]) {
            return index;
        }
    }
    return NSNotFound;
}

#pragma mark - Child mappers

- (void)addChildMappingProvider:(id <CDMappingProvider>)mappingProvider {
    if (mappingProvider) {
        NSString *key = NSStringFromClass(mappingProvider.inputType);

        id provider = childMappers[key];
        if (provider) {
            [NSException raise:@"MLEntityMapper: nvalid child mapping provider" format:@"Child mapper for type %@ already exists", key];
        }

        [childMappers setObject:mappingProvider forKey:key];
    }
}

- (id <CDMappingProvider>)childMappingProviderForType:(Class)type {
    NSString *key = NSStringFromClass(type);
    id<CDMappingProvider> provider = [childMappers objectForKey:key];

    if (!provider) {
        [NSException raise:@"MLEntityMapper: cannot find child mapper for designated type" format:@"Child mapper for %@ is not registered", key];
    }

    return provider;
}


#pragma mark - Default converters

- (id <CDMappingProvider>)mappingProviderForPropertyKind:(CDEntityPropertyKind)propertyKind associatedType:(Class)associatedType {
    switch (propertyKind) {
        case CDEntityPropertyString:
            return [CDEntityMapper passConverterForString];
        case CDEntityPropertyNumeric:
            return [CDEntityMapper passConverterForNumber];
        case CDEntityPropertyDate:
            return [CDEntityMapper converterForDateInYyyymmdd];
        case CDEntityPropertyUrl:
            return [CDEntityMapper urlConverter];
        case CDEntityPropertyArray:
            return [CDEntityMapper arrayConverterWithChildMapper:[self childMappingProviderForType:associatedType]];
        case CDEntityPropertyLocale:
            return [CDEntityMapper localeConverter];
        case CDEntityPropertyReference:
            return [self childMappingProviderForType:associatedType];
        default:
            [NSException raise:@"MLEntityMapper: invalid property kind" format:@"Invalid property kind %d", propertyKind];
    }
}

+ (CDEntityValueConverter *)converterForDateInEpoch {
    static CDEntityValueConverter *converterForDateInEpoch = nil;

    if (converterForDateInEpoch == nil) {
        CDUnmapperBlock mapper = ^ id (id value) {
            NSDate *date = value;
            return date ? [NSNumber numberWithDouble:([date timeIntervalSince1970] * 1000.0)] : [NSNull null];
        };

        CDMapperBlock unmapper = ^ id (id value) {
            NSNumber *number = value;
            return number ? [NSDate dateWithTimeIntervalSince1970:([number doubleValue] / 1000.0)] : nil;
        };

        converterForDateInEpoch =
                [[CDEntityValueConverter alloc] initWithInputType:[NSDate class] outputType:[NSNumber class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return converterForDateInEpoch;
}

+ (CDEntityValueConverter *)converterForDateInMmddyyyy {
    static CDEntityValueConverter *converterForDateInMmddyyyy = nil;

    if (converterForDateInMmddyyyy == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            NSString *string = value;

            if (string) {
                NSDate *date = nil;

                if (string.length == 10) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"MM/dd/yyyy";
                    date = [formatter dateFromString:string];
                }

                if (date) {
                    return date;
                } else {
                    CDLog(@"WARN: unexpected MM/dd/yyyy date format (%@)", string);
                    return nil;
                }
            }

            return nil;
        };

        CDMapperBlock mapper = ^ id (id value) {
            NSDate *date = value;
            id object = nil;

            if (date) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"MM/dd/yyyy";
                object = [formatter stringFromDate:date];
            }

            return object;
        };

        converterForDateInMmddyyyy =
                [[CDEntityValueConverter alloc] initWithInputType:[NSDate class] outputType:[NSString class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return converterForDateInMmddyyyy;
}

+ (CDEntityValueConverter *)converterForDateInYyyymmdd {
    static CDEntityValueConverter *converterForDateInYyyymmdd = nil;

    if (converterForDateInYyyymmdd == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            NSString *string = value;

            if (string) {
                NSDate *date = nil;

                if (string.length == 10) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"yyyy-MM-dd";
                    date = [formatter dateFromString:string];
                }

                if (date) {
                    return date;
                } else {
                    CDLog(@"WARN: unexpected yyyy-MM-dd date format (%@)", string);
                    return nil;
                }
            }

            return nil;
        };

        CDMapperBlock mapper = ^ id (id value) {
            NSDate *date = value;
            id object = nil;

            if (date) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyy-MM-dd";
                object = [formatter stringFromDate:date];
            }

            return object;
        };

        converterForDateInYyyymmdd =
                [[CDEntityValueConverter alloc] initWithInputType:[NSDate class] outputType:[NSString class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return converterForDateInYyyymmdd;
}

+ (CDEntityValueConverter *)urlConverter {
    static CDEntityValueConverter *urlConverter = nil;

    if (urlConverter == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            NSString *string = value;
            NSURL *url = nil;

            if (string) {
                url = [NSURL URLWithString:string];
                if (!url) {
                    CDLog(@"WARN: unexpected url format %@", string);
                }
            }

            return url;
        };

        CDMapperBlock mapper = ^ id (id value) {
            NSURL *url = value;
            id object = nil;

            if (url) {
                object = [url absoluteString];
            }

            return object;
        };

        urlConverter = [[CDEntityValueConverter alloc] initWithInputType:[NSURL class] outputType:[NSString class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return urlConverter;
}

+ (CDEntityValueConverter *)localeConverter {
    static CDEntityValueConverter *localeConverter = nil;

    if (localeConverter == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            NSString *string = value;
            NSLocale *locale = nil;

            if (string) {
                locale = [[NSLocale alloc] initWithLocaleIdentifier:string];
                if (!locale) {
                    CDLog(@"WARN: unexpected locale format %@", string);
                }
            }

            return locale;
        };

        CDMapperBlock mapper = ^ id (id value) {
            NSLocale *locale = value;
            id object = nil;

            if (locale) {
                object = locale.localeIdentifier;
            }

            return object;
        };

        localeConverter =
                [[CDEntityValueConverter alloc] initWithInputType:[NSLocale class] outputType:[NSString class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return localeConverter;
}

+ (CDEntityValueConverter *)passConverterForString {
    static CDEntityValueConverter *converter = nil;

    if (converter == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            return value;
        };

        CDMapperBlock mapper = ^ id (id value) {
            return value;
        };

        converter = [[CDEntityValueConverter alloc] initWithInputType:[NSString class] outputType:[NSString class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return converter;
}

+ (CDEntityValueConverter *)passConverterForNumber {
    static CDEntityValueConverter *converter = nil;

    if (converter == nil) {
        CDUnmapperBlock unmapper = ^ id (id value) {
            return value;
        };

        CDMapperBlock mapper = ^ id (id value) {
            return value;
        };

        converter = [[CDEntityValueConverter alloc] initWithInputType:[NSNumber class] outputType:[NSNumber class] mapperBlock:mapper unmapperBlock:unmapper];
    }

    return converter;
}

+ (CDEntityValueConverter *)arrayConverterWithChildMapper:(CDEntityMapper *)mapper {
    CDUnmapperBlock unmapper = ^ id (id value) {
        NSArray *inArray = value;
        NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:inArray.count];

        for (id object in inArray) {
            id unmapped = [mapper unmap:object];
            if (!unmapped) {
                unmapped = [NSNull null];
            }
            [outArray addObject:unmapped];
        }

        return outArray;
    };

    CDMapperBlock mapperBlock = ^ id (id value) {
        NSArray *inArray = value;
        NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:inArray.count];

        for (id object in inArray) {
            id mapped = [mapper map:object];
            if (!mapped) {
                mapped = [NSNull null];
            }
            [outArray addObject:mapped];
        }

        return outArray;
    };

    return [[CDEntityValueConverter alloc] initWithInputType:[NSArray class] outputType:[NSArray class] mapperBlock:mapperBlock unmapperBlock:unmapper];
}

@end