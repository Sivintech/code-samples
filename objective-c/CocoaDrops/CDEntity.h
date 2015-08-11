//
// Created by Arseni Buinitsky
//

#import <Foundation/Foundation.h>

/**
 * Base class for your model entities. With proper help, gives you automatic support for:
 *  - NSCoding for key-value coders
 *  - readable description with values for descriptive properties only
 *  - prettyDescription with gived indentation level (multiline, with pretty-printing other CDEntity objects)
 *  - isEqual/hashCode
 *  - isIdentityEqual which does the same as isEqual, but if any identity properties were given, checks only them
 *
 * Define + (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor to tune how properties are interpreted.
 *
 * See CDEntityDescriptor on more details.
 */
@interface CDEntity : NSObject<NSCoding>

- (NSString *)prettyDescription;
- (NSString *)prettyDescriptionIndent:(NSUInteger)indentLevel;
- (NSString *)prettyDescriptionFull:(BOOL)full;
- (NSString *)prettyDescription:(NSUInteger)indentLevel full:(BOOL)full;

- (BOOL)isEqualIdentity:(id)entity;

@end