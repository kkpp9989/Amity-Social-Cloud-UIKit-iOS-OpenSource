//
//  AmityMentionConfigurations.h
//  AmitySDK
//
//  Created by Hamlet on 25.08.21.
//  Copyright © 2021 Amity. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Mention configurations Object
 */
__attribute__((objc_subclassing_restricted))
@interface AmityMentionConfigurations : NSObject

/**
 Whether can mention channel in message
 */
@property (nonatomic, assign) BOOL isMentionAllEnabled;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
