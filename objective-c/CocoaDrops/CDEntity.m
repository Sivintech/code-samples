//
// Created by Arseni Buinitsky
//

#import "CDEntity.h"
#import "CDEntityDescriptor.h"

#define StringTruncationLength 128

@interface CDEntity()

+ (NSString *)prettyDescriptionForArray:(NSArray *)array full:(BOOL)full;
+ (NSString *)prettyDescriptionForObject:(id)object full:(BOOL)full;

- (BOOL)property:(CDEntityProperty *)property equalsWith:(CDEntity *)entity;

@end


@implementation CDEntity

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding]) {
        [NSException raise:@"Unsupported Archiver" format:@"Only Keyed Archivers are supported"];
    }

    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];

    for (CDEntityProperty *property in descriptor.properties.allValues) {
        id value = [self valueForKey:property.name];
        [coder encodeObject:value forKey:property.name];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    if (![coder allowsKeyedCoding]) {
        [NSException raise:@"Unsupported Archiver" format:@"Only Keyed Archivers are supported"];
    }

    CDEntity *entity = [self init];
    if (entity) {
        CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];

        for (CDEntityProperty *property in descriptor.properties.allValues) {
            id value = [coder decodeObjectForKey:property.name];
            if (value != [NSNull null]) {
                [self setValue:value forKey:property.name];
            }
        }
    }
    return entity;
}

#pragma mark - KVC support

- (void)setNilValueForKey:(NSString *)key {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    CDEntityProperty *property = descriptor.properties[key];
    
    if (property.kind == CDEntityPropertyNumeric) {
        [self setValue:[NSNumber numberWithInteger:0] forKey:key];
    } else {
        // this should not happen if my understanding is correct; checking just in case (Arseni Buinitsky)
        CDLog(@"[WARN]: MLEntity: unexpected property target in setNilValueForKey: (%@)", property);
    }
}

#pragma mark - isEqual: and company

- (BOOL)property:(CDEntityProperty *)property equalsWith:(CDEntity *)entity {
    
    id value1 = [self valueForKey:property.name];
    id value2 = [entity valueForKey:property.name];
    
    if ((value1 == nil) != (value2 == nil)) {
        return NO;
        
    } else if (value1 != nil) {
        BOOL ok;
        
        if (property.kind == CDEntityPropertyString) {
            ok = [value1 isEqualToString:value2];
        } else if (property.kind == CDEntityPropertyNumeric) {
            ok = [value1 isEqualToNumber:value2];
        } else if (property.kind == CDEntityPropertyArray) {
            ok = [value1 isEqualToArray:value2];
        } else if (property.kind == CDEntityPropertyDate) {
            ok = [value1 isEqualToDate:value2];
        } else {
            ok = [value1 isEqual:value2];
        }
        
        if (!ok) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)isEqual:(id)object {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    
    if (object == nil || [self class] != [object class]) {
        return NO;
    } else {
        for (CDEntityProperty *property in descriptor.properties.allValues) {
            if (![self property:property equalsWith:object]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)isEqualIdentity:(id)entity {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    
    if (descriptor.identityProperties.count == 0) {
        return [self isEqual:entity];
        
    } else if (entity == nil || [self class] != [entity class]) {
        return NO;
        
    } else {
        for (NSString *propertyName in descriptor.identityProperties) {
            if (![self property:descriptor.properties[propertyName] equalsWith:entity]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (NSUInteger)hash {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    
    NSUInteger hash = 1;
    NSUInteger prime = 31;
    
    for (NSString *propertyName in descriptor.properties.allKeys) {
        hash = (prime * hash) + [[self valueForKey:propertyName] hash];
    }
    
    return hash;
}

#pragma mark - Descriptions

+ (NSString *)prettyDescriptionForArray:(NSArray *)array full:(BOOL)full {
    NSString *description = @"@[";
    BOOL empty = YES;
    
    for (id item in array) {
        empty = NO;
        
        NSString *itemDescription = [[self prettyDescriptionForObject:item full:full] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        description = [description stringByAppendingFormat:@"\n\t%@", itemDescription];
    }
    
    return [description stringByAppendingFormat:@"%@]", empty ? @"" : @"\n"];
}

+ (NSString *)prettyDescriptionForObject:(id)object full:(BOOL)full {
    if ([object isKindOfClass:[CDEntity class]]) {
        return [object prettyDescription:0 full:full];
        
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [self prettyDescriptionForArray:object full:full];
        
    } else {
        NSString *description = [object description];
        
        if (description.length > (StringTruncationLength + 3)) {
            NSUInteger difference = description.length - StringTruncationLength,
                offset = (description.length - difference) / 2.0;
            
            description = [NSString stringWithFormat:@"%@...%@", [description substringToIndex:offset], [description substringFromIndex:(description.length - offset)]];
        }
        
        return description;
    }
}

- (NSString *)description {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    
    NSArray *properties = descriptor.descriptiveProperties;
    if (properties.count == 0) {
        properties = descriptor.identityProperties;
    }
    
    __block NSString *propertiesDescription = @"";
    
    [properties enumerateObjectsUsingBlock:^ (NSString *propertyName, NSUInteger index, BOOL *stop) {
        CDEntityProperty *property = descriptor.properties[propertyName];        
        propertiesDescription = [propertiesDescription stringByAppendingFormat:@"%@%@: %@", (index > 0 ? @", " : @""), property.name, [self valueForKey:property.name]];
    }];
    
    return [NSString stringWithFormat:@"<%@ %p%@%@>", NSStringFromClass([self class]), self, (propertiesDescription.length > 0 ? @" " : @""), propertiesDescription];
}

- (NSString *)prettyDescription {
    return [self prettyDescription:0 full:NO];
}

- (NSString *)prettyDescriptionIndent:(NSUInteger)indentLevel {
    return [self prettyDescription:indentLevel full:NO];
}

- (NSString *)prettyDescriptionFull:(BOOL)full {
    return [self prettyDescription:0 full:full];
}

- (NSString *)prettyDescription:(NSUInteger)indentLevel full:(BOOL)full {
    CDEntityDescriptor *descriptor = [CDEntityDescriptor forClass:[self class]];
    
    NSArray *properties;
    if (full) {
        properties = descriptor.properties.allKeys;
    } else {
        properties = descriptor.descriptiveProperties;
        if (properties.count == 0) {
            properties = descriptor.identityProperties;
        }
    }
    
    NSString *description = [NSString stringWithFormat:@"<%@ %p", NSStringFromClass([self class]), self];
    
    BOOL first = YES;
    for (NSString *propertyName in properties) {
        NSString *propertyValue = [[CDEntity prettyDescriptionForObject:[self valueForKey:propertyName] full:full] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        description = [description stringByAppendingFormat:@"%@%@ = %@", (first ? @" " : @", "), propertyName, propertyValue];
        first = NO;
    }

    return [description stringByAppendingString:@">"];
}

@end