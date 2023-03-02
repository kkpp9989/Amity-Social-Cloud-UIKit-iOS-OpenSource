//
//  EkoChannelModel.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EkoChannelModel : EkoRealmModel

@property NSString *channelId;
@property BOOL isDistinct;
@property BOOL isMuted;
@property BOOL isRateLimited;
@property NSInteger rateLimit;
@property NSString *type;
@property NSData *metadata;
@property NSString *displayName;
@property NSInteger memberCount;
@property NSInteger messageCount;
@property NSInteger readToSegment;
@property NSInteger lastMentionedSegment;
@property NSDate *lastActivity;
@property NSString *currentUserMembership;
@property NSString *tags;
@property (nullable) NSString *avatarFileId;
@property BOOL isDeleted;
@property NSInteger moderatorMemberCount;

+ (NSString *)getChannelMembershipForType:(AmityChannelMembershipType) type;

@end

NS_ASSUME_NONNULL_END
