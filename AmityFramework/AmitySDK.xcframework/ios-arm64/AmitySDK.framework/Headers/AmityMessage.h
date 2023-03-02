//
//  AmityMessageModel.h
//  AmityMessage
//
//  Created by amity on 1/18/18.
//  Copyright © 2018 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/AmityEnums.h>

@class AmityMessage;
@class AmityUser;
@class AmityMessageEditor;
@class AmityImageData;
@class AmityFileData;
@class AmityMentionees;
@class AmityClient;
@class EkoUserModel;
@class AmityMentionees;
@class AmityVideoData;

/**
 Message Type

 - AmityMessageTypeText: A text message.
 - AmityMessageTypeImage: An image message.
 - AmityMessageTypeFile: A file message.
 - AmityMessageTypeCustom: A custom message.
 - AmityMessageTypeVideo: A video message. 
 */
typedef NS_ENUM(NSInteger, AmityMessageType) {
    AmityMessageTypeText,
    AmityMessageTypeImage,
    AmityMessageTypeFile,
    AmityMessageTypeCustom,
    AmityMessageTypeAudio,
    AmityMessageTypeVideo
};

/// Size of uploaded media
typedef NS_ENUM(NSInteger, AmityMediaSize) {
    /// Up to 160 pixels per dimension.
    AmityMediaSizeSmall,
    /// Up to 600 pixels per dimension.
    AmityMediaSizeMedium,
    /// Up to 1500 pixels per dimension.
    AmityMediaSizeLarge,
    /// Original upload resolution (or same as AmityMediaSizeLarge if image was not uploaded with fullImage set to YES).
    AmityMediaSizeFull
};

/// Instance of message created in a channel.
__attribute__((objc_subclassing_restricted))
@interface AmityMessage : NSObject
/**
 Uniquely identifies this message.
 */
@property (nonnull, strong, readonly, nonatomic) NSString *messageId;
/**
 Identifies the channel where this message has been posted.
 */
@property (nonnull, strong, readonly, nonatomic) NSString *channelId;
/**
 The message author `userId`.
 */
@property (nonnull, strong, readonly, nonatomic) NSString *userId;
/**
 The message author.
 */
@property (nullable, strong, readonly, nonatomic) AmityUser *user;
/**
 The message data.
 */
@property (nullable, strong, readonly, nonatomic) NSDictionary *data;
/**
 The reaction data.
 */
@property (nullable, strong, readonly, nonatomic) NSDictionary *reactions;
/**
 The message type.
 */
@property (readonly, nonatomic) AmityMessageType messageType;
/**
 Whether the message has been deleted.
 */
@property (assign, readonly, nonatomic) BOOL isDeleted;
/**
 Whether the message has been edited. If editedAt > createdAt, this value is true.
 */
@property (assign, readonly, nonatomic) BOOL isEdited;


@property (assign, readonly, nonatomic) BOOL isMessageEdited;
/**
 The sync state of the message.
 */
@property (readonly, nonatomic) AmitySyncState syncState;
/**
   Number of people that have flagged this message
 */
@property (assign, readonly, nonatomic) NSUInteger flagCount;
/**
   Number of reaction on this message
 */
@property (assign, readonly, nonatomic) NSUInteger reactionsCount;
/**
   Number of people that have read this message
 */
@property (assign, readonly, nonatomic) NSUInteger readByCount;
/**
 A sequence number of a message in channel
 */
@property (assign, readonly, nonatomic) NSUInteger channelSegment;
/**
 The message creation time.
 */
@property (nonnull, strong, readonly, nonatomic) NSDate *createdAtDate;
/**
 The last time this message has been updated.
 */
@property (nonnull, strong, readonly, nonatomic) NSDate *editedAtDate;
/**
   The message tags.
 */
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *tags;
/**
   The list of my reactions to this message.
 */
@property (nonnull, strong, readonly, nonatomic) NSArray <NSString *> *myReactions;
/**
 The messageId of the parent message.
 */
@property (nullable, nonatomic) NSString *parentId;
/**
 The number of children of this message.
 */
@property (assign, nonatomic) NSUInteger childrenNumber;

/**
 FileId associated with this message
 */
@property (nullable, strong, nonatomic) NSString *fileId;

/**
 * The metadata
 */
@property (nullable, strong, readonly, nonatomic) NSDictionary<NSString *, id> *metadata;

/**
 * The mentionees propery provides information about mention type and userIds if mention type is user.
 */
@property (nullable, strong, readonly, nonatomic) NSArray<AmityMentionees *> *mentionees;

/**
 Gets the file data associated with this message.
 
 @return: Returns AmityFileData if present. Else returns nil.
 */
- (nullable AmityFileData *)getFileInfo;

/**
 Gets the image data associated with this message.
 
 @return: Returns AmityImageData if present. Else returns nil.
 */
- (nullable AmityImageData *)getImageInfo;

/**
 Gets the video data associated with this message.
 
 @return: Returns AmityVideoData if present. Else returns nil.
 */
- (nullable AmityVideoData *)getVideoInfo;

/**
 Gets the thumbnail image data associated with this message.
 
 @return: Returns AmityImageData if present. Else returns nil.
 */
- (nullable AmityImageData *)getVideoThumbnailImageInfo;

@end
