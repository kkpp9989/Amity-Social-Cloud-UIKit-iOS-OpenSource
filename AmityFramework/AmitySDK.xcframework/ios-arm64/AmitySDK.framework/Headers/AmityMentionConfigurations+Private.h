//
//  AmityMentionConfigurations+Private.h
//  AmitySDK
//
//  Created by Hamlet on 27.08.21.
//  Copyright © 2021 Amity. All rights reserved.
//

#import <AmitySDK/AmityMentionConfigurations.h>
#import <AmitySDK/EkoMentionConfigurationsModel.h>

@interface AmityMentionConfigurations()

@property (nonnull, strong, readwrite, nonatomic) EkoMentionConfigurationsModel *model;

- (nonnull instancetype)initWithModel:(nonnull EkoMentionConfigurationsModel *)model NS_DESIGNATED_INITIALIZER;

@end
