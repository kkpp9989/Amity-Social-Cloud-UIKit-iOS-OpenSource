//
//  AmityComment+Private.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 5/21/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <AmitySDK/AmityComment.h>
#import <AmitySDK/EkoCommentModel.h>
#import <AmitySDK/EkoModelProtocol.h>

@interface AmityComment () <EkoModelProtocol>

@property (nonnull, strong, readwrite, nonatomic) EkoCommentModel *model;

@property (assign, readonly, nonatomic) int cachedIsFlagByMe;
@property (readonly, nonatomic) BOOL bloomFilterIsFlagByMe;

@end
