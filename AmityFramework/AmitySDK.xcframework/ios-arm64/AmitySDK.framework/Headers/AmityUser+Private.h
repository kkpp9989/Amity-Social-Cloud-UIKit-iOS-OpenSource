//
//  AmityUser+Private.h
//  AmitySDK
//
//  Created by amity on 2/22/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/AmityUser.h>
#import <AmitySDK/EkoUserModel.h>

@interface AmityUser () <EkoModelProtocol>

@property (nonnull, strong, readwrite, nonatomic) EkoUserModel *model;

/**
   check the EkoUser model for definition
 */
@property (assign, readonly, nonatomic) int cachedIsFlagByMe;
@property (readonly, nonatomic) BOOL bloomFilterIsFlagByMe;

@end
