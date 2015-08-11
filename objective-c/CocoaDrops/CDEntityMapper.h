//
// Created by Arseni Buinitsky
//

#import <Foundation/Foundation.h>
#import "CDEntityDescriptor.h"


@class CDEntityValueConverter;


typedef id (^CDUnmapperBlock)(id value);
typedef id (^CDMapperBlock)(id value);


typedef void (^CDPostMappingBlock)(NSMutableDictionary *dictionary, id entity);
typedef void (^CDPostUnmappingBlock)(NSMutableDictionary *dictionary, id entity);


@protocol CDMappingProvider

@property (readonly) Class inputType;
@property (readonly) Class outputType;

- (id)map:(id)object;
- (id)unmap:(id)object;

@end


/**
* Single property mapping description. Includes converter and in/out property names
*/
@interface CDEntityPropertyMapping : NSObject

@property (copy) NSString *originalName;
@property (copy) NSString *mappedName;
@property (strong) id<CDMappingProvider> mappingProvider;
@property (assign) BOOL required;

@end


/**
* Object for converting values from one type to another
*/
@interface CDEntityValueConverter : NSObject<CDMappingProvider>

- (id)initWithInputType:(Class)inputType outputType:(Class)outputType mapperBlock:(CDMapperBlock)mapper unmapperBlock:(CDUnmapperBlock)unmapper;

@property (readonly) CDUnmapperBlock unmapper;
@property (readonly) CDMapperBlock mapper;

@end


/**
* Object for mapping NSEntity to NSDictionary with various conversions in process
* TODO: support for detecting unmapped fields in NSDictionary
* TODO: support for validation (required, enum validity etc)
*/
@interface CDEntityMapper : NSObject<CDMappingProvider>

+ (CDEntityMapper *)forClass:(Class)entityClass;
+ (CDEntityMapper *)forClass:(Class)entityClass withChildMappingProvider:(id<CDMappingProvider>)childProvider;
+ (CDEntityMapper *)forClass:(Class)entityClass withChildMappingProviders:(NSArray *)childProviders;

- (void)resetMappedName:(NSString *)mappedName forProperty:(NSString *)propertyName;
- (void)resetMappingProvider:(id <CDMappingProvider>)mappingProvider forProperty:(NSString *)propertyName;
- (void)resetRequiredFlag:(BOOL)required forProperty:(NSString *)propertyName;

@property (copy) CDPostMappingBlock postMapBlock;
@property (copy) CDPostUnmappingBlock postUnmapBlock;

- (id<CDMappingProvider>)childMappingProviderForType:(Class)type;

- (id <CDMappingProvider>)mappingProviderForPropertyKind:(CDEntityPropertyKind)propertyKind associatedType:(Class)associatedType;

+ (CDEntityValueConverter *)converterForDateInEpoch;
+ (CDEntityValueConverter *)converterForDateInMmddyyyy;
+ (CDEntityValueConverter *)converterForDateInYyyymmdd;
+ (CDEntityValueConverter *)arrayConverterWithChildMapper:(id <CDMappingProvider>)mapper;

@end