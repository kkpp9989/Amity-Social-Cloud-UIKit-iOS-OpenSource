//
//  EkoCommentModel.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 5/21/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/EkoHashFlagModel.h>
#import <AmitySDK/EkoRealmModel.h>

@class EkoUserModel;
@class EkoMessageModel;

@protocol EkoCommentModel;
@protocol EkoUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface EkoCommentModel : EkoRealmModel
// This is the mongo _id. We use it internally for subscribing to mqtt service
@property (nonatomic) NSString *internalId;

@property (nonatomic) NSString *commentId;
@property (nullable, nonatomic) NSString *parentId;
@property (nonatomic) NSString *referenceId;
@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *referenceType;
@property (nonatomic) NSString *dataType;
@property (assign, nonatomic) NSInteger childrenNumber;
@property (nonnull, nonatomic) RLMArray<EkoCommentModel *><EkoCommentModel> *childrenComments;
@property (assign, nonatomic) NSInteger reactionsCount;
@property (assign, nonatomic) NSInteger flagCount;
@property (nullable, nonatomic) NSData *data;
@property (nullable, nonatomic) NSData *metadata;
@property (nonatomic, nullable) NSData *reactions;
@property (strong) NSString *myReactions;
@property (nonatomic) NSDate *editedAt;
@property (assign, nonatomic) BOOL isDeleted;
@property (nullable, nonatomic) EkoHashFlagModel *hashFlag;
@property (nullable, nonatomic) EkoUserModel *user;
@property (nullable, strong) NSData *mentionees;
@property (nullable, nonatomic) RLMArray<EkoUserModel *><EkoUserModel> *mentionedUsers;

@property (readonly) RLMLinkingObjects *queryStreams;

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

#pragma mark:- Local Cache Related Properties

/// MQTT Subscription topic path returned from backend
@property (nonnull, nonatomic) NSString *path;

+ (void)locallyDeleteCommentId:(NSString *)commentId hardDelete:(BOOL)hardDelete inRealm:(RLMRealm *)realm;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoCommentModel);
