//
//  AmitySDKRequest.h
//  AmitySDK
//
//  Created by amity on 2/21/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <Foundation/Foundation.h>

@class AmityObject;
@class AmityNotificationToken;
@class ASCNetworkRequestToken;
@protocol EkoModelProtocol;
@class EkoRealmModel;
@class AmityClient;
@class ASCError;

NS_ASSUME_NONNULL_BEGIN

typedef _Nullable id<EkoModelProtocol> (^ ModelTransformer)(EkoRealmModel *object);

/// Instance of Live Object. This class is used in sdk to represent objects whose changes can be notified to any user observing the object. Example: `AmityObject<AmityUser>`
///
/// Life cycle of live object observation is directly tied to its token. Once token is deallocated, observation ends.
/// ```swift
/// var token: AmityNotificationToken?
/// var userRepo: AmityUserRepository?
///
/// token = userRepo?.getUser("user-id").observe { liveObject, error in
///     // Whenever property of live object changes, this block gets called
/// }
/// ```
/// To stop observation, you can just set `token = nil`.
///
__attribute__((objc_subclassing_restricted))
@interface AmityObject <__covariant ObjectType> : NSObject

/// Current object data status.
@property (nonatomic) AmityDataStatus dataStatus;

/// Current local object loading status.
@property (nonatomic) AmityLoadingStatus loadingStatus;

/// Direct access to this object.
@property (nullable, readonly, nonatomic) ObjectType object;

/// Once a single error occurs, live object will terminate all observations.
@property (nullable, strong, nonatomic) NSError *error;

/// Adds a block to observe changes to underlying object.
///
/// Observers will be notified when the object is available. In case the object doesn't exist, or was unavailable, an error will be passed. Observe block can be called multiple times. Observed data can be fetched from local store or might be freshly fetched from server. You can check `dataStatus` property to determine freshness.
///
/// - Parameters:
///   - block Block to be executed when there is any changes to the observing object.
/// - Return: Notification token tied to this observation. Token should be retained strongly for observation. Set the token to nil, if you want observation to end.
- (nonnull AmityNotificationToken *)observeWithBlock:(void (^)(AmityObject<ObjectType> * _Nonnull object, NSError * _Nullable error))block;

/// Adds a block to observe changes to underlying object.
///
/// Observers will be notified when the object is available. In case the object doesn't exist, or was unavailable, an error will be passed. Observe block will be called only once.
///
/// - Parameters:
///   - block Block to be executed when there is any changes to the observing object.
/// - Return: Notification token tied to this observation. Token should be retained strongly for observation. Set the token to nil, if you want observation to end.
- (nonnull AmityNotificationToken *)observeOnceWithBlock:(void (^)(AmityObject<ObjectType> * _Nonnull object, NSError * _Nullable error))block;

/**
   Block call of `init` and `new` because AmityObject cannot be created directly
 **/
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
