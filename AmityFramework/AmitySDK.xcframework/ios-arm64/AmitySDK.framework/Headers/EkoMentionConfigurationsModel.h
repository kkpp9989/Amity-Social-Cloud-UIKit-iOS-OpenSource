//
//  EkoMentionConfigurationsModel.h
//  AmitySDK
//
//  Created by Hamlet on 27.08.21.
//  Copyright © 2021 Amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EkoMentionConfigurationsModel : EkoRealmModel

@property (assign, nonatomic) BOOL enabled;
@property (assign, nonatomic) BOOL isAllowMentionedChannelEnabled;
@property (nonatomic) NSString *mentionConfigurationsId;

@end

NS_ASSUME_NONNULL_END
