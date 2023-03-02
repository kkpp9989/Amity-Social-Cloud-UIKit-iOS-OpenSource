//
//  EkoChannelModel.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//


#import <AmitySDK/EkoHashFlagModel.h>
#import <AmitySDK/EkoRealmModel.h>

@interface EkoUserModel : EkoRealmModel

@property (nonnull, nonatomic) NSString *internalId;
@property (nonnull, nonatomic) NSString *userId;
@property (nullable, nonatomic) NSString *displayName;

@property (nonnull, nonatomic) RLMArray<RLMString> *roles;
@property (nonnull, nonatomic) RLMArray<RLMString> *permissions;

@property (nonatomic) NSInteger flagCount;
@property (nullable, nonatomic) EkoHashFlagModel *hashFlag;
@property (nonnull, strong) NSData *metadata;
@property (nullable, strong, nonatomic) NSString *avatarFileId;
@property (nullable, strong, nonatomic) NSString *avatarCustomUrl;
@property (nonnull, strong, nonatomic) NSString *userDescription;
@property BOOL isGlobalBan;
@property BOOL isDeleted;

/**
   This value is set to:
 * 0 when it is undetermined
 * 1 when it is flagged by me
 * -1 when it is NOT flagged by me

   @note
   I would like this property to be a BOOL, however:
 * there's no way to have it optional (BOOL is always YES or NO),
 * we also want this to be stored as a primitive because we use realm.

 */
@property (nonatomic) int cachedIsFlagByMe;


#pragma mark:- Local cache related properties

/**
 Whether this model is to be included when user query for all users
 */
@property (assign, nonatomic) BOOL includeInAllQuery;

/**
 Whether this model is to be included when user query for used based on displayname
 */
@property (assign, nonatomic) BOOL includeInSearchResult;

+ (nonnull instancetype)ekoCreateOrUpdateInRealm:(nonnull RLMRealm *)realm withJSON:(nonnull NSDictionary<NSString *, id> *)json;

/// MQTT Subscription topic path returned from backend
@property (nonnull, nonatomic) NSString *path;

// Change RLMArray<RLMSTring> to [NSString]. We want to loop through permissions & access it as String in swift.
// But doing so will trigger compiler warning about typecasting unrelated object would always fail.
//
// Note: Once the model are migrated to swift, access it directly from List<String>.
- (nonnull NSSet<NSString *> *)getAllPermissions;

@end

RLM_COLLECTION_TYPE(EkoUserModel);
