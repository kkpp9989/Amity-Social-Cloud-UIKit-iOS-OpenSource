//
//  AmityFollowModel.h
//  AmitySDK
//
//  Created by Nontapat Siengsanor on 25/5/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>

@class EkoUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface AmityFollowRelationshipModel : EkoRealmModel

@property NSString *relationshipId;
@property NSString *from;
@property NSString *to;
@property NSString *status;

@property EkoUserModel *fromUser;
@property EkoUserModel *toUser;

@property (readonly) RLMLinkingObjects *queryStreams;

+ (NSString *)primaryKeyFromUserId:(NSString *)fromUserId toUserId:(NSString *)toUserId;

@end

NS_ASSUME_NONNULL_END
