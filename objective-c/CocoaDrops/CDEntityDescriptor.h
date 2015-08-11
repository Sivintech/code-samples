//
// Created by Arseni Buinitsky
//

#import <Foundation/Foundation.h>

typedef enum {
    CDEntityPropertyString = 1,
    CDEntityPropertyNumeric,
    CDEntityPropertyDate,
    CDEntityPropertyUrl,
    CDEntityPropertyArray,
    CDEntityPropertyLocale,
    CDEntityPropertyReference
} CDEntityPropertyKind;


@interface CDEntityProperty : NSObject

- (id)initWithName:(NSString *)name kind:(CDEntityPropertyKind)kind associatedType:(Class)associatedType required:(BOOL)required;

@property (readonly) NSString *name;
@property (readonly) CDEntityPropertyKind kind;
@property (readonly) Class associatedType;
@property (readonly) BOOL required;

@end


@interface CDEntityDescriptor : NSObject

+ (CDEntityDescriptor *)forClass:(Class)entityClass;

- (id)initWithClass:(Class)entityClass;

- (void)ignoreProperty:(NSString *)propertyName;
- (void)require:(BOOL)require property:(NSString *)propertyName;

- (void)setIdentityProperty:(NSString *)propertyName;
- (void)setIdentityProperties:(NSArray *)propertyNames;

- (void)setDescriptiveProperties:(NSArray *)propertyNames;

- (void)setContainedType:(Class)type forArrayProperty:(NSString *)propertyName;

@property (readonly) NSArray *identityProperties;
@property (readonly) NSArray *descriptiveProperties;
@property (readonly) Class entityClass;
@property (readonly) NSDictionary *properties;

@end