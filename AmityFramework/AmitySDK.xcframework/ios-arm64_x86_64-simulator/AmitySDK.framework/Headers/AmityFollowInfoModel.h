//
//  AmityFollowInfoModel.h
//  AmitySDK
//
//  Created by Nishan Niraula on 2/4/22.
//  Copyright © 2022 Amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>
#import <AmitySDK/AmityFollowRelationshipModel.h>

NS_ASSUME_NONNULL_BEGIN

// FIXME: Rename this to ASC or Eko model.
/// Instance containing information about followers & following. This class is not meant to be subclassed or used directly by user.
@interface AmityFollowInfoModel : EkoRealmModel

@property (nonatomic) NSString *userId;
@property (assign, nonatomic) NSInteger followerCount;
@property (assign, nonatomic) NSInteger followingCount;
@property (assign, nonatomic) NSInteger pendingCount;

@property (nullable) AmityFollowRelationshipModel *relationship;

+ (void)updateRelationshipInRealm:(RLMRealm *)realm relationship:(AmityFollowRelationshipModel *)relationship forUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
