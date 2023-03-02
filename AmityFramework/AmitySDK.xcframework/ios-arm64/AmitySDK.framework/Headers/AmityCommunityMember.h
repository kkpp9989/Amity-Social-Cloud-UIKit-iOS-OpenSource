//
//  AmityCommunityMember.h
//  AmitySDK
//
//  Created by Michael Abadi on 05/08/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/AmityUser.h>
#import <AmitySDK/EkoModelProtocol.h>

@class AmityClient;

/// Instance of member of community.
@interface AmityCommunityMember : NSObject <EkoModelProtocol>

/// The channelId
@property (nonnull, strong, readonly, nonatomic) NSString *channelId;

/// The communityId
@property (nonnull, strong, readonly, nonatomic) NSString *communityId;

/// The userId
@property (nonnull, strong, readonly, nonatomic) NSString *userId;

/// The user displayName
@property (nonnull, strong, readonly, nonatomic) NSString *displayName;

/// User object which belongs to this userId.
@property (nullable, readonly, nonatomic) AmityUser *user;

/// Banned status
@property (assign, readonly, nonatomic) BOOL isBanned;

/// The community member  metadata.
@property (nonnull, strong, readonly, nonatomic) NSDictionary <NSString *, id> *metadata;

/// The user last activity time.
@property (nonnull, strong, readonly, nonatomic) NSDate *lastActivityDate;

/// The date/time when the user first joins the community.
@property (nonnull, strong, nonatomic) NSDate *createdAt;

/// The date/time when the member is updated.
@property (nonnull, strong, nonatomic) NSDate *updatedAt;

/// The community membership status
@property (readonly) AmityCommunityMembershipType membership;

/// Roles for this membership
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *roles;

@end

