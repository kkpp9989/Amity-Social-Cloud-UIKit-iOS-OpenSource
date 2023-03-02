//
//  EkoFeedModel.h
//  AmitySDK
//
//  Created by Sarawoot Khunsri on 15/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EkoFeedModel : EkoRealmModel

@property (nonatomic) NSString *feedId;
@property (nonatomic) NSString *feedType;
@property (nonatomic) NSString *targetId;
@property (nonatomic) NSString *targetType;
@property (nonatomic, assign) NSInteger postCount;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoFeedModel);
