//
//  EkoCommentQueryStreamModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 22/3/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

#import <Realm/Realm.h>
#import <AmitySDK/EkoRealmModel.h>

@class EkoCommentModel;
@protocol EkoCommentModel;

NS_ASSUME_NONNULL_BEGIN

@interface EkoCommentQueryStreamModel : EverySDKRealmModel

@property NSString *identifier;
@property RLMArray<EkoCommentModel *><EkoCommentModel> *objects;

@end

NS_ASSUME_NONNULL_END
