//
//  AmityMessage+Private.h
//  AmitySDK
//
//  Created by amity on 2/12/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/AmityMessage.h>
#import <AmitySDK/EkoMessageModel.h>
#import <AmitySDK/EkoModelProtocol.h>

@interface AmityMessage () <EkoModelProtocol>

@property (nonnull, strong, readwrite, nonatomic) EkoMessageModel *model;

+ (nonnull NSString *)valueForMessageType:(AmityMessageType)type;
+ (nonnull NSString *)valueForMediaSize:(AmityMediaSize)size;

@property (assign, readonly, nonatomic) int cachedIsFlagByMe;
@property (readonly, nonatomic) BOOL bloomFilterIsFlagByMe;

@end
