//
//  AmityStream+Private.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 23/9/2563 BE.
//  Copyright © 2563 amity. All rights reserved.
//

#import <AmitySDK/AmityStream.h>
#import <AmitySDK/EkoModelProtocol.h>
#import <AmitySDK/EkoStreamModel.h>
#import <AmitySDK/AmityStreamStatus.h>

@interface AmityStream () <EkoModelProtocol>

// redeclare model from protocol
@property (nonnull, strong, readwrite, nonatomic) EkoStreamModel *model;

@end

