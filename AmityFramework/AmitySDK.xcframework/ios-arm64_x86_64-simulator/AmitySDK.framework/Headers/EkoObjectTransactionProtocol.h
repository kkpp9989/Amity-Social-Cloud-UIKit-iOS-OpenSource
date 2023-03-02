//
//  EkoTransactionProtocol.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>

@class RLMRealm;
@class EkoNetworkRequest;

@protocol EkoObjectTransactionProtocol

- (nonnull EkoNetworkRequest *)request;

- (nullable EkoRealmModel *)getObjectWithStore:(nonnull RLMRealm *)store NS_SWIFT_NAME(getObject(with:));

// NOTE: This function "is not" called within realm write transaction.
// You must begin realm write transaction on your own.
- (nullable EkoRealmModel *)processResult:(nullable NSDictionary <NSString *, id> *)result withStore:(nonnull RLMRealm *)store;

#pragma mark - Server Error Handling

// Place the code in this function to process the error from server.
// This function is triggered before `deleteObjectWhen400400`.
- (void)processError:(nonnull NSError *)error withStore:(nonnull RLMRealm *)store;

// Normally, when live object receive 400400 error, this function will be triggered.
// Please consider to implment the logic to delete object from local cache.
// However, if this is not suitable for your logic, we can also opt-out by implement empty code.
//
// NOTE: This function is called within realm write transaction.
- (void)deleteObjectWhen400400WithStore:(nonnull RLMRealm *)store;

#pragma mark - Tombstone Support

// Implement the logic find the dead object from the tombstone.
// If this is not suitable, you can simply return `false` to opt-out tombstone logic.
- (BOOL)findDeadObjectInTombstoneWithStore:(nonnull RLMRealm *)store;

// Implement the logic save the dead object into the tombstone.
// If this is not suitable, you can simply write empty code to opt-out tombstone logic.
//
// NOTE: This function is called within realm write transaction.
- (void)saveDeadObjectToTombstoneWithStore:(nonnull RLMRealm *)store;

@end
