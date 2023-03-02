//
//  EkoTransactionProtocol.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import <AmitySDK/EkoCollectionTransactionDelegate.h>

@protocol EkoCollectionTransactionProtocol;
@class EkoNetworkRequest;

typedef NS_CLOSED_ENUM(NSUInteger, AmityFetchPageType) {
    AmityFetchFirstPage,
    AmityFetchNextPage,
    AmityFetchPreviousPage,
    AmityFetchLastPage
};

@protocol EkoCollectionTransactionProtocol <NSObject>

- (nonnull RLMResults *)queryFromStore:(nonnull RLMRealm *)store;
- (nonnull EkoNetworkRequest *)requestForPageType:(AmityFetchPageType)type;
- (void)processResult:(nullable NSDictionary <NSString *, id> *)result pageType:(AmityFetchPageType)type withStore:(nonnull RLMRealm *)store;
- (BOOL)hasNext;
- (BOOL)hasPrevious;

@optional
- (void)setupDelegate:(nonnull id<EkoCollectionTransactionDelegate>)delegate;
- (void)processError:(nonnull NSError *)error pageType:(AmityFetchPageType)type withStore:(nonnull RLMRealm *)store;

@end
