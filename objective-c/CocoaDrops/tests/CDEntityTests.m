//
//  CDEntityTests.m
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/20/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "CDEntityTests.h"
#import "CDEntity.h"
#import "CDEntityDescriptor.h"
#import "TestCDEntities.h"


@implementation CDEntityTests

- (NSString *)replaceHex:(NSString *)string {
    return [string stringByReplacingOccurrencesOfString:@"0x[0-9a-f]+" withString:@"%ADDR%" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)];
}


- (void)testDescriptions {
    RootEntity *entity = [RootEntity newWithTitle:@"Root Entity" info:@"Some info about root entity" rating:5.0 comments:@[
                          [Comment newWithCommentId:@"1" author:@"Man One" text:@"Hello, World!" date:[NSDate dateWithTimeIntervalSince1970:0]],
                          [Comment newWithCommentId:@"2" author:@"Man Two" text:@"Hello, Objective-C" date:[NSDate dateWithTimeIntervalSince1970:1.0]],
                          [Comment newWithCommentId:@"3" author:@"Man Three" text:@"Foo Bar" date:[NSDate dateWithTimeIntervalSince1970:2.0]] ]];
    
    RootEntityWithId *entityWithId = [RootEntityWithId newWithTitle:@"Root Entity" info:@"Some info about root entity" rating:5.0 comments:@[
                                      [Comment newWithCommentId:@"4" author:@"Man One" text:@"Hello, World!" date:[NSDate dateWithTimeIntervalSince1970:0]],
                                      [Comment newWithCommentId:@"5" author:@"Man Two" text:@"Hello, Objective-C" date:[NSDate dateWithTimeIntervalSince1970:1.0]],
                                      [Comment newWithCommentId:@"6" author:@"Man Three" text:@"Foo Bar" date:[NSDate dateWithTimeIntervalSince1970:2.0]] ]];
    
    RootEntityWithDescriptive *entityWithDesc = [RootEntityWithDescriptive newWithTitle:@"Root Entity" info:@"Some info about root entity" rating:5.0 comments:@[
                                                 [Comment newWithCommentId:@"7" author:@"Man One" text:@"Hello, World!" date:[NSDate dateWithTimeIntervalSince1970:0]],
                                                 [Comment newWithCommentId:@"8" author:@"Man Two" text:@"Hello, Objective-C" date:[NSDate dateWithTimeIntervalSince1970:1.0]],
                                                 [Comment newWithCommentId:@"9" author:@"Man Three" text:@"Foo Bar" date:[NSDate dateWithTimeIntervalSince1970:2.0]] ]];
    
    NSString *actual = [self replaceHex:entity.description];
    NSString *expected = @"<RootEntity %ADDR%>";
    STAssertTrue([actual isEqualToString:expected], @"CDEntity gives incorrect description (%@) expected (%@)", actual, expected);
    
    actual = [self replaceHex:entityWithId.description];
    expected = @"<RootEntityWithId %ADDR% title: Root Entity>";
    STAssertTrue([actual isEqualToString:expected], @"CDEntity gives incorrect description (%@) expected (%@)", actual, expected);
    
    actual = [self replaceHex:entityWithDesc.description];
    expected = @"<RootEntityWithDescriptive %ADDR% info: Some info about root entity>";
    STAssertTrue([actual isEqualToString:expected], @"CDEntity gives incorrect description (%@) expected (%@)", actual, expected);
}

- (void)testPrettyDescriptions {
    RootEntity *entity = [RootEntity newWithTitle:@"Root Entity" info:@"Some info about root entity" rating:5.0 comments:@[
                          [Comment newWithCommentId:@"1" author:@"Man One" text:@"Hello, World!" date:[NSDate dateWithTimeIntervalSince1970:0]],
                          [Comment newWithCommentId:@"2" author:@"Man Two" text:@"Hello, Objective-C" date:[NSDate dateWithTimeIntervalSince1970:1.0]],
                          [Comment newWithCommentId:@"3" author:@"Man Three" text:@"Foo Bar" date:[NSDate dateWithTimeIntervalSince1970:2.0]] ]];
    
    NSString *actual = [self replaceHex:[entity prettyDescription]];
    NSString *expected = @"<RootEntity %ADDR%>";
    STAssertTrue([actual isEqualToString:expected], @"CDEntity gives incorrect pretty description (%@) expected (%@)", actual, expected);

    actual = [self replaceHex:[entity prettyDescriptionFull:YES]];
    expected = @"<RootEntity %ADDR% title = Root Entity, info = Some info about root entity, averageRating = 5, comments = @[\n"
                "\t\t<Comment %ADDR% commentId = 1, author = Man One, text = Hello, World!, date = 1970-01-01 00:00:00 +0000>\n"
                "\t\t<Comment %ADDR% commentId = 2, author = Man Two, text = Hello, Objective-C, date = 1970-01-01 00:00:01 +0000>\n"
                "\t\t<Comment %ADDR% commentId = 3, author = Man Three, text = Foo Bar, date = 1970-01-01 00:00:02 +0000>\n"
                "\t]>";
    STAssertTrue([actual isEqualToString:expected], @"CDEntity gives incorrect pretty description (%@) expected (%@)", actual, expected);
}

- (void)testEquals {
    for (NSUInteger testIndex = 0; testIndex < 1000; ++testIndex) {
        NSUInteger n1_1 = arc4random_uniform(2),
                n1_2 = arc4random_uniform(2),
                n2_1 = arc4random_uniform(2),
                n2_2 = arc4random_uniform(2);
        
        void (^checkBlock)(EntityForEqualityTest *, EntityForEqualityTest*) = ^ (EntityForEqualityTest *e1, EntityForEqualityTest *e2) {
            
            BOOL expectedEquals = e1.identifier == e2.identifier
                && [e1.name isEqualToString:e2.name]
                && [e1.number isEqualToNumber:e2.number];
            BOOL expectedEqualsIdentity = e1.identifier == e2.identifier;
            
            BOOL equals = [e1 isEqual:e2];
            BOOL equalsIdentity = [e1 isEqualIdentity:e2];
            
            STAssertEquals(expectedEquals, equals, @"CDEntity.isEqual: implementation is incorrect");
            STAssertEquals(expectedEqualsIdentity, equalsIdentity, @"CDEntity.isEqualIdentity: implementation is incorrect");
            
            if (equals) {
                STAssertEquals(e1.hash, e2.hash, @"CDEntity.hash implementation is incorrect");
            }
        };
        
        EntityForEqualityTest *entity1 = [[EntityForEqualityTest alloc] init];
        entity1.identifier = 150;
        entity1.name = [NSString stringWithFormat:@"name%d", n1_1];
        entity1.number = [NSNumber numberWithUnsignedInt:n1_2];
        
        EntityForEqualityTest *entity2 = [[EntityForEqualityTest alloc] init];
        entity2.identifier = 150;
        entity2.name = [NSString stringWithFormat:@"name%d", n2_1];
        entity2.number = [NSNumber numberWithUnsignedInt:n2_2];
        
        checkBlock(entity1, entity2);
        
        NSUInteger n1 = arc4random_uniform(2),
                n2 = arc4random_uniform(2);
        entity1.identifier = n1;
        entity2.identifier = n2;
        
        checkBlock(entity1, entity2);
    }
}

@end
