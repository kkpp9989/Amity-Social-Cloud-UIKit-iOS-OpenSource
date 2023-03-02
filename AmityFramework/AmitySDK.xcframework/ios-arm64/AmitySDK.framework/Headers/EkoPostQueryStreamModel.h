//
//  EkoPostQueryStreamModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 9/8/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Realm/Realm.h>
#import <AmitySDK/EkoRealmModel.h>

@class EkoPostModel;
@protocol EkoPostModel;

NS_ASSUME_NONNULL_BEGIN

@interface EkoPostQueryStreamModel : EverySDKRealmModel

@property NSString *identifier;
@property RLMArray<EkoPostModel *><EkoPostModel> *objects;

@end

NS_ASSUME_NONNULL_END
