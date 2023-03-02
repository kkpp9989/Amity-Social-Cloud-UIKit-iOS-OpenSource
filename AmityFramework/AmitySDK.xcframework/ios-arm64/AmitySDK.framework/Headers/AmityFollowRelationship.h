//
//  AmityFollowRelationship.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 25/5/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/AmityEnums.h>

@class AmityUser;
@class AmityClient;
@class EkoUserModel;

NS_ASSUME_NONNULL_BEGIN

/// Instance which represents relationship between two users in sdk.
@interface AmityFollowRelationship : NSObject <EkoModelProtocol>

/**
 * A user id of the person who is following
 */
@property (nonnull, strong, readonly, nonatomic) NSString *sourceUserId;

/**
 * A user id of the person who is being followed
 */
@property (nonnull, strong, readonly, nonatomic) NSString *targetUserId;

/**
 * A user object of the person who is following. This can be nil in some cases.
 * If its nil, use `getUser:` method from `AmityUserRepository` class to fetch user information.
 */
@property (nullable, strong, readonly, nonatomic) AmityUser *sourceUser;

/**
 * A user object of the person who is being followed. This can be nil in some cases.
 * If its nil, use `getUser:` method from `AmityUserRepository` class to fetch user information.
 */
@property (nullable, strong, readonly, nonatomic) AmityUser *targetUser;

/**
 * A follow status between 2 users
 */
@property (assign, readonly, nonatomic) enum AmityFollowStatus status;

@end

NS_ASSUME_NONNULL_END
