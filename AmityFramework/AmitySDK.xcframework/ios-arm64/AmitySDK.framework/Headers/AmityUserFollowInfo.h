//
//  AmityFollowInfo.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 2/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <AmitySDK/AmityEnums.h>

NS_ASSUME_NONNULL_BEGIN

@class AmityClient;

/// Instance which contains information about followers / following of current user.
@interface AmityUserFollowInfo : NSObject

@property (nonnull, strong, readonly, nonatomic) NSString *targetUserId;
@property (readonly, nonatomic) enum AmityFollowStatus status;
@property (readonly, nonatomic) NSInteger followersCount;
@property (readonly, nonatomic) NSInteger followingCount;

@end

NS_ASSUME_NONNULL_END
