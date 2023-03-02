//
//  AmityPost+Private.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 4/16/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/AmityPost.h>
#import <AmitySDK/EkoPostModel.h>
#import <AmitySDK/EkoModelProtocol.h>

@interface AmityPost () <EkoModelProtocol>

// Redeclare model from protocol
@property (nonnull, strong, readwrite, nonatomic) EkoPostModel *model;

@property (assign, readonly, nonatomic) int cachedIsFlagByMe;
@property (readonly, nonatomic) BOOL bloomFilterIsFlagByMe;

/// Returns internal mongo id for this post target
- (nonnull NSString *)getPostTargetInternalId;


@end
