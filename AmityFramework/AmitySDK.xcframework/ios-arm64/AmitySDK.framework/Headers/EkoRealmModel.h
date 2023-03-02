//
//  EkoModel.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Realm/Realm.h>

@interface EverySDKRealmModel : RLMObject

@end

@interface EkoRealmModel : EverySDKRealmModel

@property (nonnull) NSDate *createdAt;
@property (nonnull) NSDate *updatedAt;

/// Mostly, we only work with this property when we want to support optimistic operation on object level.
/// - Any object that we receive from the remote source must be only `synced`.
/// - However, when the SDK perform optimistic operation this value could be `syncing | synced | error`.
///
/// The default value is 0 means `synced`.
@property NSInteger syncState;

/// This is a backing storage of `syncState`, please use `syncState` instead.
@property (nullable) NSNumber<RLMInt> *_syncState;

/// Stores the last time this model was updated from the server, in order for client to determine if it is necessary to fetch latest data
@property (nullable) NSDate *_lastFetchTime;

/// Stores the time-to-live duration that the SDK can return the object without fetching the new one from the server.
/// See also: https://ekoapp.atlassian.net/l/cp/3aAh60F9
@property (nullable) NSDate *TTL;

// FIXME: We must remove this after comment creation is converted to callback version. No longer need to optout, we must apply checking unsynced objects to all model.
- (BOOL)hackyShouldCheckUnsyncedObject;

/// This function updates the object only if we already have the same object stored in the local database.
/// This is useful when we need to handle partial payload, if the object does not exist in the local database, we discard the payload.
+ (nullable instancetype)ekoUpdateIfExistsInRealm:(nonnull RLMRealm *)realm
                                         withJSON:(nonnull NSDictionary<NSString*, id> *)json;

/// This function create or update the object to the local database.
/// NOTE: This function requires the full object payload, to handle partial payload please use ekoUpdateIfExistsInRealm instead.
+ (nonnull instancetype)ekoCreateOrUpdateInRealm:(nonnull RLMRealm *)realm
                                        withJSON:(nonnull NSDictionary<NSString *, id> *)json;

@end

