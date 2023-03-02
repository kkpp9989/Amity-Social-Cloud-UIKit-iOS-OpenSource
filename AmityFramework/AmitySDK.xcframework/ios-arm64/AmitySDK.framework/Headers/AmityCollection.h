//
//  AmityCollection.h
//  AmitySDK
//
//  Created by amity on 1/28/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>
#import <Foundation/Foundation.h>

@class AmityCollection;
@class AmityNotificationToken;
@class AmityCollectionChange;
@class ASCNetworkRequestToken;
@class ASCError;

NS_ASSUME_NONNULL_BEGIN

/// Instance of Live Collection. This class is used in sdk to represent list of objects whose changes can be notified to any user observing the collection. Example: `AmityCollection<AmityUser>`
///
/// Life cycle of live collection observation is directly tied to its token. Once token is deallocated, observation ends.
/// ```swift
/// var token: AmityNotificationToken?
/// var userRepo: AmityUserRepository?
///
/// token = userRepo?.getUsers().observe { liveCollection, error in
///     // Whenever property of any object within the collection changes, this block gets called
/// }
/// ```
/// To stop observation, you can just set `token = nil`.
///
/// Live collection supports pagination. Infact collection are paginated by default. It fetches 20 objects per page. You can fetch next or previous page of collection by calling `nextPage()` or `previousPage()` method.
@interface AmityCollection<__covariant ObjectType> : NSObject

/// Live collection data status. Once data is fetched from server, its status would be .fresh
@property (readonly, nonatomic) AmityDataStatus dataStatus;

/// Live collection loading status
@property (readonly, nonatomic) AmityLoadingStatus loadingStatus;

/// If user can query for previous page
@property (readonly, nonatomic) BOOL hasPrevious;

/// If user can query for next page
@property (readonly, nonatomic) BOOL hasNext;

/// Total count of objects currently in collection. This count can increase when user query for more pages.
- (NSUInteger)count;

/// Returns instance of object at given index
/// - Parameters:
///   - idx Index of object in collection
/// - Returns: Instance of that object
- (nullable ObjectType)objectAtIndex:(NSUInteger)idx;

/**
 * Returns all objects of this live collection.
 *
 * @note This is equavalent to @code
 * var allObjects: [ObjectType] = []
 * for i in 0..<collection.count() {
 *     if let object = collection.object(at: i) {
 *         allObjects.add(object)
 *     }
 * }
 * return allObjects;
 * @endcode
 */

/// Gets list of all objects currently in collection. This is equivalent to code
///
/// ```swift
/// var allObjects: [ObjectType] = []
/// for i in 0..<collection.count() {
///     if let object = collection.object(at: i) {
///         allObjects.add(object)
///     }
/// }
///
/// return allObjects;
/// ```
/// - Returns: Array of all objects currently in collection
- (NSArray<ObjectType> *)allObjects;

/// Resets the current collection to first page fetched.
- (void)resetPage;

/// Requests more objects for previous page.
- (void)previousPage;

/// Requests more objects for next page
- (void)nextPage;

/// Invalidates current collection.
- (void)invalidate;

/// Adds a block to observe changes to underlying objects in collection.
///
/// Observers will be notified when the object has changed or collection is available. In case the collection doesn't exist, or is unavailable, an error will be passed. Observe block can be called multiple times. Observed data can be fetched from local store or might be freshly fetched from server. You can check `dataStatus` property to determine freshness.
///
/// - Parameters:
///   - block Block to be executed when there is any changes to the observing object.
/// - Return: `AmityNotificationToken` tied to this observation. Token should be retained strongly for observation. Set the token to nil, if you want observation to end.
- (nonnull AmityNotificationToken *)observeWithBlock:(void (^)(AmityCollection<ObjectType> * _Nonnull collection, AmityCollectionChange * _Nullable changes, NSError * _Nullable error))block;

/// Adds a block to observe changes to underlying objects in collection.
///
/// Observers will be notified when the object has changed or collection is available. In case the collection doesn't exist, or is unavailable, an error will be passed. Observe block will be called only once.
///
/// - Parameters:
///   - block Block to be executed when there is any changes to the observing object.
/// - Return: `AmityNotificationToken` token tied to this observation. Token should be retained strongly for observation. Set the token to nil, if you want observation to end.
- (nonnull AmityNotificationToken *)observeOnceWithBlock:(void (^)(AmityCollection<ObjectType> * _Nonnull collection, AmityCollectionChange * _Nullable changes, NSError * _Nullable error))block;
/**
   Block call of `init` and `new` because AmityObject cannot be created directly
 **/
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 *  Represents changes in a AmityCollection
 */
@interface AmityCollectionChange : NSObject

/**
 * The indexes of objects inserted
 */
@property (nullable, strong, readonly, nonatomic) NSArray <NSNumber *> *insertions;

/**
 * The indexes of objects deleted
 */
@property (nullable, strong, readonly, nonatomic) NSArray <NSNumber *> *deletions;

/**
 * The indexes of objects modified
 */
@property (nullable, strong, readonly, nonatomic) NSArray <NSNumber *> *modifications;

@end

NS_ASSUME_NONNULL_END
