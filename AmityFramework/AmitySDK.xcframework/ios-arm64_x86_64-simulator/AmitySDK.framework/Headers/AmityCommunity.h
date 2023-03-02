//
//  AmityGroup.h
//  AmitySDK
//
//  Created by Michael Abadi on 03/07/20.
//  Copyright © 2020 amity. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/AmityUser.h>

@class AmityCommunity;
@class AmityCommunityModeration;
@class AmityImageData;
@class AmityCommunityCategory;
@class ASCUtils;
@class AmityClient;
@class EkoUserModel;
@class AmityCommunityParticipation;

__attribute__((objc_subclassing_restricted))
/// Instance of a community. You can create posts in communities.
@interface AmityCommunity : NSObject <EkoModelProtocol>

/// The unique identifier for the community
@property (nonnull, strong, readonly, nonatomic) NSString *communityId;

/// The unique identifier for the channel of the community
@property (nonnull, strong, readonly, nonatomic) NSString *channelId;

/// The unique identifier for the user id of the creator
@property (nonnull, strong, readonly, nonatomic) NSString *userId;

/// User object which belongs to this userId.
@property (nullable, nonatomic) AmityUser *user;

/// The display name of the community
@property (nonnull, strong, readonly, nonatomic) NSString *displayName;

/// The description of the community
@property (nonnull, strong, readonly, nonatomic) NSString *communityDescription;

/// Number of post count on this community
@property (assign, readonly, nonatomic) NSUInteger postsCount;

/// Number of member who follow on this community
@property (assign, readonly, nonatomic) NSUInteger membersCount;

/// Community meta data
@property (nullable, strong, readonly, nonatomic) NSDictionary<NSString *, id> *metadata;

/// Community tags
@property (nullable, strong, readonly, nonatomic) NSArray<NSString *> *tags;

/// The status of the community if it is an official
@property (assign, readonly, nonatomic) BOOL isOfficial;

/// The status of the community if it is a public
@property (assign, readonly, nonatomic) BOOL isPublic;

/// The status of the community if user join the community
@property (assign, readonly, nonatomic) BOOL isJoined;

/// The status of the community if only admin able to post to the community
@property (assign, readonly, nonatomic) BOOL onlyAdminCanPost;

/// The creation date of the community
@property (nonnull, strong, nonatomic) NSDate *createdAt;

/// @abstract The community last edited time
/// @discussion The updated time is updated for updated data on the community
@property (nonnull, strong, nonatomic) NSDate *updatedAt;

/// A moderation instance
@property (nonnull, readonly, nonatomic) AmityCommunityModeration *moderate;

/// The avatar model of the community
@property (nullable, strong, readonly, nonatomic) AmityImageData *avatar;

/// Category Ids for this community
@property (nonnull, nonatomic) NSArray<NSString *> *categoryIds;

/// Array of categories this community belongs to.
@property (nonnull, nonatomic) NSArray<AmityCommunityCategory *> *categories;

/// Whether this community is deleted or not
@property (assign, nonatomic) BOOL isDeleted;

/// Returns participation instance
@property (nonnull, readonly, nonatomic) AmityCommunityParticipation *participation;

/// The status of the post review is enable or not
@property (assign, readonly, nonatomic) BOOL isPostReviewEnabled;

/// Number of post count filter by feedType on this community
- (NSInteger) getPostCount:(AmityFeedType)feedType NS_SWIFT_NAME(getPostCount(feedType:));  

/// mqtt topic path
@property (nonnull, nonatomic) NSString *topicPath;

/// Subscribes to event for this community.
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)subscribeEvent:(AmityCommunityEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

/// Unsubscribes to event for this community.
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)unsubscribeEvent:(AmityCommunityEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

@end
