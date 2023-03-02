//
//  EkoHashFlagModel.h
//  AmitySDK
//
//  Created by Federico Zanetello on 12/3/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/EkoRealmModel.h>

@interface EkoHashFlagModel : EverySDKRealmModel

@property (nullable, nonatomic) NSString *ekoHash;
@property (nonatomic) NSInteger hashes;
@property (nonatomic) NSInteger bits;

+ (nonnull instancetype)ekoCreateInRealm:(nonnull RLMRealm *)realm withJSON:(nonnull NSDictionary<NSString *, id> *)json;

@end
