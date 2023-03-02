//
//  AmityMyFollowInfo+Private.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 17/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/AmityMyFollowInfo.h>
#import <AmitySDK/AmityFollowInfoModel.h>
#import <AmitySDK/EkoModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AmityMyFollowInfo() <EkoModelProtocol>

@property (nonnull, strong, nonatomic) AmityFollowInfoModel *model;
@property (nonnull, strong) AmityClient *client;

- (instancetype)initWithResponse:(NSDictionary<NSString *, id> *)response andClient:(AmityClient *)client;

@end

NS_ASSUME_NONNULL_END

