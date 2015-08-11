//
//  TestCDEntities.h
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/22/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDEntity.h"


@interface RootEntity : CDEntity

+ (RootEntity *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments;

@property NSString *title;
@property NSString *info;
@property double averageRating;

@property NSArray *comments;

@end


@interface RootEntityWithId : CDEntity

+ (RootEntityWithId *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments;

@property NSString *title;
@property NSString *info;
@property double averageRating;

@property NSArray *comments;

@end


@interface RootEntityWithDescriptive : RootEntity

+ (RootEntityWithDescriptive *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments;

@end


@interface Comment : CDEntity

+ (Comment *)newWithCommentId:(NSString *)commentId author:(NSString *)author text:(NSString *)text date:(NSDate *)date;

@property NSString *commentId;
@property NSString *author;
@property NSString *text;
@property NSDate *date;

@end


@interface EntityForEqualityTest : CDEntity

@property long long identifier;
@property NSString *name;

@property NSNumber *number;

@end
