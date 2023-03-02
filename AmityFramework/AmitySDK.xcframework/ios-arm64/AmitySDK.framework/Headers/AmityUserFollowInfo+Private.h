//
//  AmityUserFollowInfo+Private.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 2/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/AmityUserFollowInfo.h>
#import <AmitySDK/AmityFollowInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AmityUserFollowInfo() <EkoModelProtocol>

@property (nonnull, strong, nonatomic) AmityFollowInfoModel *model;
@property (nonnull, strong) AmityClient *client;

- (instancetype)initWithResponse:(NSDictionary<NSString *, id> *)response andClient:(AmityClient *)client;

@end

NS_ASSUME_NONNULL_END
