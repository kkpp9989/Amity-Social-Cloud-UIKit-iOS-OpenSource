//
//  AmityCollection+Private.h
//  AmitySDK
//
//  Created by amity on 1/31/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Realm/Realm.h>
#import <AmitySDK/AmityCollection.h>
#import <AmitySDK/EkoCollectionTransactionProtocol.h>
#import <AmitySDK/AmityObject+Private.h>
#import <AmitySDK/EkoCollectionTransactionDelegate.h>

@class AmityClient;

@interface AmityCollection () <EkoCollectionTransactionDelegate>

- (nonnull instancetype)initWithTransaction:(nonnull id<EkoCollectionTransactionProtocol>)transaction
                                     client:(nonnull AmityClient *)client
                           modelTransformer:(nonnull ModelTransformer)modelTransformer;

@end

@interface AmityCollectionChange ()

- (nonnull instancetype)initWithRLMChanges:(nonnull RLMCollectionChange *)changes;

@end
