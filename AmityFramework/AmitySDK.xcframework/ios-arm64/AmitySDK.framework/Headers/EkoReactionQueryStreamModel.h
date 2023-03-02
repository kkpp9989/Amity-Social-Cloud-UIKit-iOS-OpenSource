//
//  EkoReactionQueryStreamModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 20/7/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import <AmitySDK/EkoRealmModel.h>

@class EkoReactionModel;
@protocol EkoReactionModel;

NS_ASSUME_NONNULL_BEGIN

@interface EkoReactionQueryStreamModel : EverySDKRealmModel

@property NSString *identifier;
@property RLMArray<EkoReactionModel *><EkoReactionModel> *objects;

@end

NS_ASSUME_NONNULL_END
