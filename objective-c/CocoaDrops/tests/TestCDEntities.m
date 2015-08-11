//
//  TestCDEntities.m
//  CDEntities
//
//  Created by Arseni Buinitsky on 4/22/13.
//  Copyright (c) 2013 Home. All rights reserved.
//

#import "TestCDEntities.h"
#import "CDEntityDescriptor.h"


@implementation RootEntity

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[Comment class] forArrayProperty:@"comments"];
}

+ (RootEntity *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments {
    RootEntity *obj = [[RootEntity alloc] init];
    obj.title = title;
    obj.info = info;
    obj.averageRating = rating;
    obj.comments = comments;
    return obj;
}

@end


@implementation RootEntityWithId

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setContainedType:[Comment class] forArrayProperty:@"comments"];
    [descriptor setIdentityProperty:@"title"];
}

+ (RootEntityWithId *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments {
    RootEntityWithId *obj = [[RootEntityWithId alloc] init];
    obj.title = title;
    obj.info = info;
    obj.averageRating = rating;
    obj.comments = comments;
    return obj;
}

@end


@implementation RootEntityWithDescriptive

+ (RootEntityWithDescriptive *)newWithTitle:(NSString *)title info:(NSString *)info rating:(double)rating comments:(NSArray *)comments {
    RootEntityWithDescriptive *entity = [[RootEntityWithDescriptive alloc] init];
    entity.title = title;
    entity.info = info;
    entity.averageRating = rating;
    entity.comments = comments;
    return entity;
}

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setDescriptiveProperties:@[ @"info" ]];
}

@end


@implementation Comment

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setIdentityProperties:@[ @"commentId" ]];
    [descriptor setDescriptiveProperties:@[ @"author", @"date" ]];
}

+ (Comment *)newWithCommentId:(NSString *)commentId author:(NSString *)author text:(NSString *)text date:(NSDate *)date {
    Comment *comment = [[Comment alloc] init];
    comment.commentId = commentId;
    comment.author = author;
    comment.text = text;
    comment.date = date;
    return comment;
}

@end


@implementation EntityForEqualityTest

+ (void)fixEntityDescriptor:(CDEntityDescriptor *)descriptor {
    [descriptor setDescriptiveProperties:@[ @"identifier", @"name" ]];
    [descriptor setIdentityProperty:@"identifier"];
}

@end