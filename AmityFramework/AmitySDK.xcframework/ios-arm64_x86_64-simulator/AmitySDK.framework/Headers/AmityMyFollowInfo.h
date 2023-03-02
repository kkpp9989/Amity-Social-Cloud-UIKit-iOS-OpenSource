//
//  AmityMyFollowInfo.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 17/6/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AmityClient;

NS_ASSUME_NONNULL_BEGIN

/// Instance which contains information about followers / following of current user.
@interface AmityMyFollowInfo : NSObject

@property (assign, readonly, nonatomic) NSInteger followersCount;
@property (assign, readonly, nonatomic) NSInteger followingCount;
@property (assign, readonly, nonatomic) NSInteger pendingCount;

@end

NS_ASSUME_NONNULL_END
