//
// Created by Eakawat Tantamjarik on 4/3/2018 AD.
// Copyright (c) 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <AmitySDK/EkoRealmModel.h>
#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRLMString.h>

NS_ASSUME_NONNULL_BEGIN

@interface EkoChannelUserModel : EkoRealmModel

@property NSString *_id;
@property NSString *channelId;
@property NSString *userId;
@property NSInteger readToSegment;
@property NSInteger lastMentionedSegment;
@property NSString *membership;
@property BOOL isBanned;
@property BOOL isMuted;
@property RLMArray<EkoRLMString *> <EkoRLMString> *userRoles;
@property RLMArray<RLMString> *permissions;
@property NSString *displayName;

+ (nonnull NSString *)primaryKeyForUser:(nonnull NSString *)userId andChannel:(nonnull NSString *)channel;
+ (nonnull NSString *)stringForMembershipType:(AmityChannelMembershipType)type;

/**
 Whether this model is to be included when user query for all type of membership
 */
@property (assign, nonatomic) BOOL includeInAllQuery;

- (nonnull NSSet<NSString *> *)getAllPermissions;

@end

NS_ASSUME_NONNULL_END
