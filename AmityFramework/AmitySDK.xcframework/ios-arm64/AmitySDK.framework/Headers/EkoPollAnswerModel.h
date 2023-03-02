//
//  EkoPollAnswerModel.h
//  AmitySDK
//
//  Created by Sarawoot Khunsri on 6/8/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>
NS_ASSUME_NONNULL_BEGIN

@interface EkoPollAnswerModel : EkoRealmModel

@property (nonatomic) NSString *answerId;
@property (nonatomic) NSString *dataType;
@property (nonatomic) NSString *data;
@property (assign, nonatomic) BOOL isVotedByUser;
@property (nonatomic, assign) NSInteger voteCount;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoPollAnswerModel);
