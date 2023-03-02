//
//  AmityObject+Private.h
//  AmitySDK
//
//  Created by amity1 on 2/24/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/AmityObject.h>
#import <AmitySDK/EkoObjectTransactionProtocol.h>
#import <AmitySDK/EkoRealmModel.h>
#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@class AmityClient;

@interface AmityObject ()

- (nonnull instancetype)initWithTransaction:(nonnull id<EkoObjectTransactionProtocol>)transaction
                                     client:(AmityClient *)client
                           modelTransformer:(nonnull ModelTransformer)modelTransformer;

@end

NS_ASSUME_NONNULL_END
