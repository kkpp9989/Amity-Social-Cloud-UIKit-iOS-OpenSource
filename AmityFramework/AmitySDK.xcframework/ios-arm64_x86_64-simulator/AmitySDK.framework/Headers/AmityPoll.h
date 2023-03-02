//
//  AmityPoll.h
//  AmitySDK
//
//  Created by Sarawoot Khunsri on 16/8/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityPollAnswer.h>

@class AmityClient;

__attribute__((objc_subclassing_restricted))
/// Instance of Poll object.
@interface AmityPoll : NSObject

/**
 * The creation date of the poll
 */
@property (nonnull, strong, nonatomic) NSDate *createdAt;

/**
   @abstract The post last edited time
   @discussion The updated time is updated for updated data on the poll
 */
@property (nonnull, strong, nonatomic) NSDate *updatedAt;

/**
 Timestamp when this poll was last closed by user.
 */
@property (nonnull, strong, nonatomic) NSDate *closedAt;

/**
 * The unique identifier for the poll
 */
@property (nonnull, strong, readonly, nonatomic) NSString *pollId;

/**
 * The question for the poll
 */
@property (nonnull, strong, readonly, nonatomic) NSString *question;

/**
 * The status for the poll
 */
@property (nonnull, strong, readonly, nonatomic) NSString *status;

/**
 Determines if this poll has been closed.
 */
@property (assign, readonly, nonatomic) BOOL isClosed;

/**
 Determines if this poll can be multiple vote.
 */
@property (assign, readonly, nonatomic) BOOL isMultipleVote;

/**
 Determines if this poll has been voted.
 */
@property (assign, readonly, nonatomic) BOOL isVoted;

/**
   Time to close on this poll
 */
@property (assign, readonly, nonatomic) NSUInteger closedIn;

/**
 Array of answers
 */
@property (nonnull, nonatomic) NSArray<AmityPollAnswer *> *answers;

/**
   Number of vote on this poll
 */
@property (assign, readonly, nonatomic) NSUInteger voteCount;

@end
