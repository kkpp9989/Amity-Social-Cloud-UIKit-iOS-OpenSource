//
//  EkoCommunityUserModel.h
//  AmitySDK
//
//  Created by Michael Abadi on 10/08/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRLMString.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

// NOTE: This model gets mapped to EkoCommunityMembership model.
@interface EkoCommunityUserModel : EkoRealmModel

@property (nonatomic) NSString *_id;
@property (nonatomic) NSString *communityId;
@property (nonatomic) NSString *channelId;
@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *communityMembership;
@property BOOL isBanned;
@property (strong, nonatomic) NSDate *lastActivity;
@property (nullable, strong) NSData *metadata;
@property (nonatomic) RLMArray<EkoRLMString *> <EkoRLMString> *userRoles;
@property (nonatomic) RLMArray<RLMString> *permissions;

+ (nonnull NSString *)primaryKeyForUser:(nonnull NSString *)userId andCommunity:(nonnull NSString *)communityId;
/**
 Whether this model is to be included when user query for all type of membership
 */
@property (assign, nonatomic) BOOL includeInAllQuery;

/**
 Whether this model is to be included when user query for used based on displayname
 */
@property (assign, nonatomic) BOOL includeInSearchResult;

- (nonnull NSSet<NSString *> *)getAllPermissions;

@end

NS_ASSUME_NONNULL_END
