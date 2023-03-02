//
//  EkoReactionModel.h
//  AmitySDK
//
//  Created by Nishan Niraula on 5/21/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This is the Realm Model for Reaction. This model can be used for Message, Comments, Post and
 possibly future reaction integration.
 */
@interface EkoReactionModel : EkoRealmModel

@property NSString *_id;

// Reference Id is the id of Post, Message or Comments
@property NSString *referenceId;

// Type of reaction: Post Message or Comment
@property NSString *referenceType;

// Name of reaction
@property NSString *reactionName;

// Id of user who reacted on Post, Message or Comments
@property NSString *reactorId;

// Name of the user who reacted on Post, Message or Comments
@property NSString *reactorDisplayName;

@property (readonly) RLMLinkingObjects *queryStreams;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoReactionModel);

