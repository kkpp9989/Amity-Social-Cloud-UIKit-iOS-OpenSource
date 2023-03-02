//
//  EkoModelProtocol.h
//  AmitySDK
//
//  Created by David Zhang on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>
@class AmityClient;
@protocol EkoModelProtocol <NSObject>

@property (nonnull, strong, readonly, nonatomic) EkoRealmModel *model;
@property (nonnull, strong, readonly, nonatomic) AmityClient *client;

- (nonnull instancetype)initWithModel:(nonnull __kindof EkoRealmModel *)model
                            andClient:(nonnull AmityClient *)client;

@end
