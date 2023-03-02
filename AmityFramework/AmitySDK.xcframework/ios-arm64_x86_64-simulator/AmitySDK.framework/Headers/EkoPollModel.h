//
//  EkoPollModel.h
//  AmitySDK
//
//  Created by Sarawoot Khunsri on 27/7/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>
#import <AmitySDK/EkoPollAnswerModel.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EkoPollModel : EkoRealmModel

@property (strong, nonatomic) NSDate *closedAt;
@property (nonatomic) NSString *pollId;
@property (nonatomic) NSString *question;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *answerType;
@property (assign, nonatomic) BOOL isVoted;
@property (nonatomic, assign) NSInteger closedIn;
@property (nonnull, nonatomic) RLMArray<EkoPollAnswerModel *> <EkoPollAnswerModel> *answers;

@end

NS_ASSUME_NONNULL_END
