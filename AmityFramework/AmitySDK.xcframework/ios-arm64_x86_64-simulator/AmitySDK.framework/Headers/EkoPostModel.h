//
//  EkoPostModel.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 4/13/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoHashFlagModel.h>
#import <AmitySDK/EkoCommunityModel.h>
#import <AmitySDK/EkoCommentModel.h>
#import <AmitySDK/EkoPollModel.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EkoPostModel;
@protocol EkoUserModel;

@interface EkoPostModel : EkoRealmModel

@property (nonatomic) NSString *internalId;
@property (nonatomic) NSString *postId;
/// Id for the parent post if present.
@property (nullable, nonatomic) NSString *parentPostId;
@property (nonatomic) NSString *postedUserId;
@property (nonatomic) NSString *sharedUserId;
@property (nonatomic) NSString *dataType;
@property (nonatomic) NSString *targetType;
@property (nullable, nonatomic) NSString *targetId;
@property (assign, nonatomic) NSInteger sharedCount;
@property (strong, nonatomic) NSDate *editedAt;
@property (nonnull, strong) NSData *data;
@property (nonnull, strong) NSData *metadata;

// Array of strings ["like", "love"]
@property (strong) NSString *myReactions;

@property (nonatomic, assign) NSInteger reactionsCount;

// Dictionary of reactions & its count ["like": 1, "love": 2]
@property (nonatomic, nullable) NSData *reactions;
@property (assign, nonatomic) NSInteger flagCount;
@property (nullable, nonatomic) EkoHashFlagModel *hashFlag;
@property (nullable, nonatomic) NSString *feedId;
@property (nonatomic) NSString *feedType;
@property (nullable, strong) NSData *mentionees;
@property (nullable, nonatomic) RLMArray<EkoUserModel *><EkoUserModel> *mentionedUsers;

// Total comments count for this post.
@property (assign, nonatomic) NSInteger commentsCount;

// Actual child posts array
@property (nullable, nonatomic) RLMArray<EkoPostModel *> <EkoPostModel> *childrenPosts;

// The target community to which this post belongs to
@property (nullable, nonatomic) EkoCommunityModel *targetCommunity;

// Ids for few latest comments returned by backend
@property (nonnull, nonatomic) RLMArray<RLMString> *comments;

// Array of 5 latest comments
@property (nullable, nonatomic) RLMArray<EkoCommentModel *> <EkoCommentModel> *latestComments;

@property (nullable, nonatomic) EkoPollModel *poll;

@property (assign, nonatomic) BOOL isDeleted;

@property (readonly) RLMLinkingObjects *queryStreams;

#pragma mark:- Local Properties

/**
   This value is set to:
 * 0 when it is undetermined
 * 1 when it is flagged by me
 * -1 when it is NOT flagged by me

   @note
   I would like this property to be a BOOL, however:
 * there's no way to have it optional (BOOL is always YES or NO),
 * we also want this to be stored as a primitive because we use realm.

 */
@property (nonatomic) int cachedIsFlagByMe;

+ (void)locallyDeletePostId:(NSString *)postId hardDelete:(BOOL)hardDelete inRealm:(RLMRealm *)realm;

/// MQTT Subscription topic path returned from backend
@property (nonnull, nonatomic) NSString *path;

- (NSArray<NSString *> *)getAllLatestCommentIds;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoPostModel);
