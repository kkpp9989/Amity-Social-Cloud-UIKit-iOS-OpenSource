//
//  EkoTombstoneModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 20/9/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

#import <Realm/Realm.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

// SOURCE: https://ekoapp.atlassian.net/l/cp/NABxN0gn
//
@interface EkoTombstoneModel : EverySDKRealmModel

@property NSString *_id;

@property NSString *objectType;
@property NSString *objectId;
@property NSDate *deadTTL;

+ (void)saveDeadObjectId:(NSString *)objectId objectType:(NSString *)objectType inRealm:(RLMRealm *)realm;

+ (BOOL)findDeadObjectId:(NSString *)objectId objectType:(NSString *)objectType inRealm:(RLMRealm *)realm;

@end

NS_ASSUME_NONNULL_END
