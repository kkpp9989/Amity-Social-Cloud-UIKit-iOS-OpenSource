//
//  AmityChannelMember.h
//  AmityChat
//
//  Created by amity on 2/23/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/AmityUser.h>
#import <AmitySDK/EkoChannelUserModel.h>
#import <AmitySDK/EkoModelProtocol.h>
#import <Foundation/Foundation.h>

@class AmityClient;

/// Instance of member of a channel.
@interface AmityChannelMember : NSObject <EkoModelProtocol>

/// Id of the channel this user belongs to.
@property (nonnull, strong, readonly, nonatomic) NSString *channelId;

/// Id of the user.
@property (nonnull, strong, readonly, nonatomic) NSString *userId;

/// Corresponding `AmityUser` instance for this member.
@property (nullable, readonly, nonatomic) AmityUser *user;

/// Current user membership status for this channel.
@property (readonly) AmityChannelMembershipType membership;

/// If this user is banned in this channel.
@property (assign, readonly, nonatomic) BOOL isBanned;

/// If this user is muted in this channel.
@property (assign, readonly, nonatomic) BOOL isMuted;

/// Assigned roles for this user.
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *roles;

/// Display name of this user.
@property (nullable, strong, readonly, nonatomic) NSString *displayName;

/// The date/time when this user first joined the channel.
@property (nonnull, strong, readonly, nonatomic) NSDate *createdAt;

/// The date/time when this user is updated.
@property (nonnull, strong, readonly, nonatomic) NSDate *updatedAt;

@end
