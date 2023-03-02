//
//  AmityComment.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 5/21/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/AmityUser.h>

@class AmityMentionees;
@class AmityClient;
@class EkoUserModel;

/// Instance of comment. You can comment on post in sdk.
__attribute__((objc_subclassing_restricted))
@interface AmityComment : NSObject

/// Indicates if the object can no longer be accessed because it is invalid.
@property (nonatomic, readonly, getter = isInvalidated) BOOL invalidated;

/// Uniquely identifies this comment.
@property (nonnull, strong, readonly, nonatomic) NSString *commentId;

/// Identifies the parent where this comment has been posted.
@property (nullable, strong, readonly, nonatomic) NSString *parentId;

/// The references of this comment.
@property (nonnull, strong, readonly, nonatomic) NSString *referenceId;

/// The user id of the owner of the comment.
@property (nonnull, strong, readonly, nonatomic) NSString *userId;

/// The reference type.
@property (readonly, nonatomic) AmityCommentReferenceType referenceType;

/// The data type.
@property (readonly, nonatomic) AmityDataType dataType;

/// The comment data.
@property (nullable, strong, readonly, nonatomic) NSDictionary *data;

/// The comment metadata.
@property (nullable, strong, readonly, nonatomic) NSDictionary<NSString *, id> *metadata;

/// The reactions data.
@property (nullable, strong, readonly, nonatomic) NSDictionary *reactions;

/// The list of my reactions to this post.
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *myReactions;

/// Number of people that have flagged this comment
@property (assign, readonly, nonatomic) NSUInteger flagCount;

/// Number of children of this comment.
@property (assign, readonly, nonatomic) NSUInteger childrenNumber;

/// Array of latest 5 children comments of this comment.
@property (nonnull, nonatomic) NSArray<AmityComment *> *childrenComments;

/// Number of reaction of this comment.
@property (assign, readonly, nonatomic) NSUInteger reactionsCount;

/// The comment creation time.
@property (nonnull, strong, readonly, nonatomic) NSDate *createdAt;

/// The last time this comment has been updated.
@property (nonnull, strong, readonly, nonatomic) NSDate *updatedAt;

/// The last time this comment has been updated.
@property (nonnull, strong, readonly, nonatomic) NSDate *editedAt;

/// Whether the comment has been deleted.
@property (assign, readonly, nonatomic) BOOL isDeleted;

/// Whether the comment has been edited.
@property (assign, readonly, nonatomic) BOOL isEdited;

/// The sync state of the comment.
@property (readonly, nonatomic) AmitySyncState syncState;

/// The comment author.
@property (nullable, strong, readonly, nonatomic) AmityUser *user;

/// mqtt topic path
@property (nonnull, nonatomic) NSString *topicPath;

/// Subscribes to event for this comment.
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)subscribeEvent:(AmityCommentEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

/// Unsubscribes to event for this comment.
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)unsubscribeEvent:(AmityCommentEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

/// The mentionees propery provides information about mention and userIds.
@property (nullable, strong, readonly, nonatomic) NSArray<AmityMentionees *> *mentionees;

@end
