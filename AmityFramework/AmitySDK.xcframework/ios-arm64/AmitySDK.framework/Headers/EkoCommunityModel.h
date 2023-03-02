//
//  EkoCommunityModel.h
//  AmitySDK
//
//  Created by Michael Abadi on 03/07/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoCommunityCategoryModel.h>
#import <AmitySDK/EkoFeedModel.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@class ASCUtils;
@class EkoFileModel;

@interface EkoCommunityModel : EkoRealmModel

// This is the mongo _id. We use it internally for subscribing to mqtt service
@property (nonatomic) NSString *internalId;
@property (nonatomic) NSString *communityId;
@property (nonatomic) NSString *channelId;
@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *communityDescription;
@property (assign, nonatomic) BOOL isOfficial;
@property (assign, nonatomic) BOOL isPublic;
@property (assign, nonatomic) BOOL isJoined;
@property (assign, nonatomic) BOOL onlyAdminCanPost;
@property (nullable, strong) NSData *metadata;
@property (nullable, strong) NSData *tags;
@property (nonatomic, assign) NSInteger postsCount;
@property (nonatomic, assign) NSInteger membersCount;
@property (nonatomic) RLMArray<RLMString> *categoryIds;
@property (nullable, nonatomic) EkoFileModel *avatar;
@property (nonnull, nonatomic) RLMArray<EkoCommunityCategoryModel *> <EkoCommunityCategoryModel> *categories;
@property (nonnull, nonatomic) RLMArray<EkoFeedModel *> <EkoFeedModel> *feeds;
@property (assign, nonatomic) BOOL isDeleted;
@property (assign, nonatomic) BOOL needApprovalOnPostCreation;

// Whether this model is part of trending community
@property (assign, nonatomic) BOOL isTrending;

// Whether this model is part of recommended community
@property (assign, nonatomic) BOOL isRecommended;

// Rank order for Trending community. Default rank is 0.
@property (assign, nonatomic) NSInteger trendingRank;

// Rank order for Recommended community. Default rank is 0.
@property (assign, nonatomic) NSInteger recommendedRank;

// String which represents category ids joined by separator. This is required because
// realm doesn't allow query over array of primitive strings yet.
@property (nonatomic) NSString *categoryIdStr;


#pragma mark:- Local Cache Related Properties
/**
 Whether this model is to be included when user query for deleted models
 */
@property (assign, nonatomic) BOOL includeInDeletedQuery;

/**
Whether this model is to be included when user query for not deleted models
*/
@property (assign, nonatomic) BOOL includeInNotDeletedQuery;

/**
 Whether this model is to be included when user query for both deleted & not deleted models.
 By default this is true.
 */
@property (assign, nonatomic) BOOL includeInAllQuery;

/// MQTT Subscription topic path returned from backend
@property (nonnull, nonatomic) NSString *path;

/*
 Objc Realm Objects has some limitations when being accessed through swift code. It does not support fast enumeration. So we create some helper method as a workaround for this issue.
 Note: This will be removed after full swift migration of Realm Models
*/

// Get all category ids as [String]
- (NSArray<NSString *> *)getAllCategoryIds;

@end

NS_ASSUME_NONNULL_END
