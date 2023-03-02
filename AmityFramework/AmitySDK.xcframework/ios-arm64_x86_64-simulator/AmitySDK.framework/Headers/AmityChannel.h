//
//  AmityChannel.h
//
//  Created by amity on 1/18/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoModelProtocol.h>

@class AmityChannel;
@class AmityChannelParticipation;
@class AmityChannelModeration;
@class AmityChannelMember;
@class AmityImageData;
@class AmityClient;
@class EkoFileModel;
@class AmityChannelModeration;

/**
 * All Channel Type
 */
typedef NS_ENUM(NSUInteger, AmityChannelType) {
    AmityChannelTypeStandard,
    AmityChannelTypePrivate,
    AmityChannelTypeBroadcast,
    AmityChannelTypeConversation,
    AmityChannelTypeLive,
    AmityChannelTypeCommunity,
    AmityChannelTypeUnknown
};

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
/// Instance of a channel. You send messages in a channel.
@interface AmityChannel : NSObject <EkoModelProtocol>

/// The unique identifier for the channel
@property (strong, readonly, nonatomic) NSString *channelId;

/// Type of channel.
@property (assign, readonly, nonatomic) enum AmityChannelType channelType;

/// Metadata of this channel
@property (nullable, strong, readonly, nonatomic) NSDictionary<NSString *, id> *metadata;

/// Display name for the channel
@property (nullable, strong, readonly, nonatomic) NSString *displayName;

/// Membership status for current user in this channel,
@property (readonly) AmityChannelMembershipType currentUserMembership;

/// If this channel is distinct channel.
@property (readonly, nonatomic) BOOL isDistinct;

/// If this channel is muted
@property (readonly, nonatomic) BOOL isMuted;

/// If this channel is rate limited.
@property (readonly, nonatomic) BOOL isRateLimited;

/// Number of messages within rate limit
@property (readonly, assign, nonatomic) NSInteger rateLimit;

/// Unread message count for the current user in the channel.
@property (readonly, nonatomic) NSInteger unreadCount;

/// Whether current user has unread mentionee messages in this channel
@property (readonly, nonatomic) BOOL hasMention;

/// Total number of users in this channel.
@property (readonly, nonatomic) NSInteger memberCount;

/// Total number of messages in this channel
@property (readonly, nonatomic) NSInteger messageCount;

// TODO: Remove participation class from model. Ask user to create a separate instance
/// Creates `AmityChannelParticipation` instance and returns it.
@property (readonly, nonatomic) AmityChannelParticipation *participation;

/// Membership object for current user
@property (nullable, readonly, nonatomic) AmityChannelMember *currentMembership;

/// Creates `AmityChannelModeration` instance and returns it
@property (readonly, nonatomic) AmityChannelModeration *moderate;

/// Array of tags set for this channel.
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *tags;

/// Last activity timestamp for this channel. Last activity might be udpated when:
/// - new channel tags are set
/// - a new channel name is set
/// - a new message has been received
/// - etc
@property (strong, nonatomic) NSDate *lastActivity;

/// Channel creation timestamp
@property (nonnull, strong, readonly, nonatomic) NSDate *createdAt;

/// Channel update timestamp.
@property (nonnull, strong, readonly, nonatomic) NSDate *updatedAt;

/// If this channel has been deleted.
@property (assign, nonatomic) BOOL isDeleted;

/// File id for the avatar for this Channel. This can be used in
/// AmityFileRepository to download actual UIImage instance.
@property (nullable, strong, nonatomic) NSString *avatarFileId;

/// Total number of user moderators in this channel.
@property (readonly, nonatomic) NSInteger moderatorCount;

/// Returns avatar image data associated with this channel.
///
- (nullable AmityImageData *)getAvatarInfo;

/**
   Block call of `init` and `new` because this object cannot be created directly
 **/
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
