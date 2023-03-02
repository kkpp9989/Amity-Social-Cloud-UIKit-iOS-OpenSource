//
//  AmityPollAnswer.h
//  AmitySDK
//
//  Created by Sarawoot Khunsri on 16/8/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AmityClient;

/// Instance of answer for `AmityPoll` object.
__attribute__((objc_subclassing_restricted))
@interface AmityPollAnswer : NSObject

/**
 * The unique identifier for the answer
 */
@property (nonnull, strong, readonly, nonatomic) NSString *answerId;

/**
 * The data type of the answer
 */
@property (nonnull, strong, readonly, nonatomic) NSString *dataType;

/**
 * The text of the poll
 */
@property (nonnull, strong, readonly, nonatomic) NSString *text;

/**
 Determines if this poll has been voted.
 */
@property (assign, readonly, nonatomic) BOOL isVotedByUser;

/**
   Number of vote on this answer
 */
@property (assign, readonly, nonatomic) NSUInteger voteCount;

@end
