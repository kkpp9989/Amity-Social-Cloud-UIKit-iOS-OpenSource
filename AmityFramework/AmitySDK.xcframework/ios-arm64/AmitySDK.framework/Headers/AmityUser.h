//
//  AmityUser.h
//  AmityMessage
//
//  Created by amity on 1/18/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>

@class AmityImageData;
@class AmityClient;
@class EkoFileModel;
@class EkoUserModel;
@class AmityTopicSubscription;
@class AmityUserTopic;

typedef void (^AmityRequestCompletion)(BOOL success, NSError * _Nullable error);

/// Instance of user in sdk.
__attribute__((objc_subclassing_restricted))
@interface AmityUser : NSObject
/**
 * Id of the current user
 */
@property (nonnull, strong, readonly, nonatomic) NSString *userId;

/**
 * Display name for this user
 */
@property (nullable, strong, readonly, nonatomic) NSString *displayName;

/**
 * Timestamp when this user was first created
 */
@property (nonnull, strong, nonatomic) NSDate *createdAt;

/**
 * Timestamp when this user was last updated
 */
@property (nonnull, strong, nonatomic) NSDate *updatedAt;

/**
   Roles
 */
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *roles;

/**
   Number of people that have flagged the user
 */
@property (assign, readonly, nonatomic) NSUInteger flagCount;

/**
 * User metadata
 */
@property (nullable, strong, readonly, nonatomic) NSDictionary<NSString *, id> *metadata;

/**
 * File id for the avatar for this user. This can be used in
 * AmityFileRepository to download actual UIImage instance.
 */
@property (nullable, strong, nonatomic) NSString *avatarFileId;

/**
 * Any custom url set as avatar for this user
 */
@property (nullable, strong, nonatomic) NSString *avatarCustomUrl;

/**
 * Description for this user
 */
@property (nonnull, strong, nonatomic) NSString *userDescription;

/**
   Global banned status
 */
@property (assign, readonly, nonatomic) BOOL isGlobalBan;

/// If the user is deleted this flag will be true.
@property (assign, readonly, nonatomic) BOOL isDeleted;

/**
 Returns file information about avatar if present
 */
-(nullable AmityImageData *)getAvatarInfo;

/// Subscribes to event for this User
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)subscribeEvent:(AmityUserEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

/// Unsubscribes to event for this User
/// @param event Types of event
/// @param completion completion block to be executed after this action is complete
- (void)unsubscribeEvent:(AmityUserEvent)event withCompletion:(nonnull AmityRequestCompletion)completion;

// mqtt topic path
@property (nonnull, nonatomic) NSString *topicPath;

/// Id used for topic subscription. Use `userId` instead of this.
@property (nonnull, nonatomic) NSString *internalId;

@end
