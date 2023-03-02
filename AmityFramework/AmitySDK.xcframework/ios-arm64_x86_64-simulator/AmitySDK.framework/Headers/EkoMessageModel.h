//
//  EkoMessageModel.h
//  AmitySDK
//
//  Created by Michael Abadi Santoso on 3/1/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <AmitySDK/EkoHashFlagModel.h>
#import <AmitySDK/EkoRealmModel.h>

@class EkoFileModel;
@class EkoUserModel;
@class EkoChannelUserModel;

@protocol EkoUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface EkoMessageModel : EkoRealmModel

@property (nonatomic) NSString *messageId;
@property (nonatomic) NSString *channelId;
@property (nonatomic) NSString *userId;
@property (nonatomic) NSString *type;
@property (nullable, nonatomic) NSString *parentId;
@property (assign, nonatomic) NSInteger childrenNumber;
@property (assign, nonatomic) BOOL isDeleted;
@property (nullable, nonatomic) NSData *data;
@property (nullable, nonatomic) NSData *reactions;
@property (nonatomic) NSDate *editedAt;
@property (assign, nonatomic) NSInteger flagCount;
@property (assign, nonatomic) NSInteger reactionsCount;
@property (assign, nonatomic) NSInteger readByCount;
@property (assign, nonatomic) NSInteger channelSegment;
@property (nonatomic) NSString *tags;
@property (nonatomic) NSString *myReactions;
@property (nullable, nonatomic) EkoHashFlagModel *hashFlag;
@property (nonnull, nonatomic) NSString *fileId;
@property (nullable, nonatomic) NSString *fileName;
@property (nullable, strong) NSData *metadata;
@property (nullable, strong) NSData *mentionees;
@property (nullable, nonatomic) RLMArray<EkoUserModel *><EkoUserModel> *mentionedUsers;
/**
   This value is set to:
 * 0 when it is undetermined
 * 1 when it is flagged by me
 * -1 when it is NOT flagged by me

   @note
   I would like this property to be a BOOL, however:
 * there's no way to have it optional (BOOL is always YES or NO),
 * we also want this to be stored as a primitive because we use realm.

 */
@property (nonatomic) int cachedIsFlagByMe;

// FileModel mapped to this message
@property (nullable, nonatomic) EkoFileModel *file;

// UserModel mapped to this message
@property (nullable, nonatomic) EkoUserModel *user;

// URL of the local file attached to this message. This is used
// internally before the message gets synced to server
@property (nullable, nonatomic) NSString *localFileUrl;

@end

NS_ASSUME_NONNULL_END

