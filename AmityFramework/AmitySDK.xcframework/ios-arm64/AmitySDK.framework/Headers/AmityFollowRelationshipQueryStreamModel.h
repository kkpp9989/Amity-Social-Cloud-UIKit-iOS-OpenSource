//
//  AmityFollowRelationshipQueryStreamModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 21/7/2565 BE.
//  Copyright © 2565 BE Amity. All rights reserved.
//

#import <AmitySDK/AmitySDK.h>
#import <Realm/Realm.h>

@class AmityFollowRelationshipModel;
@protocol AmityFollowRelationshipModel;

NS_ASSUME_NONNULL_BEGIN

@interface AmityFollowRelationshipQueryStreamModel : EverySDKRealmModel

@property NSString *identifier;
@property RLMArray<AmityFollowRelationshipModel *><AmityFollowRelationshipModel> *objects;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(AmityFollowRelationshipModel);
