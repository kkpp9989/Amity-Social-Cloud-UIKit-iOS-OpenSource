//
//  EkoRLMString.h
//  AmitySDK
//
//  Created by Nishan Niraula on 12/10/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

// https://github.com/realm/realm-cocoa/issues/5334
// Realm doesnot allow query over array of primitives. So this is a workaround wrapper class to be used
// when we want to query over array of primitive strings.
@interface EkoRLMString : EkoRealmModel

@property (nonnull, nonatomic) NSString *value;

@end

RLM_COLLECTION_TYPE(EkoRLMString);

NS_ASSUME_NONNULL_END
