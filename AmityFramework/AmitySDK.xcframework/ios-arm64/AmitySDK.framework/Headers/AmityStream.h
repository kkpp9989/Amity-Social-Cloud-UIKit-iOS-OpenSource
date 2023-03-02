//
//  AmityStream.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 22/9/2563 BE.
//  Copyright © 2563 amity. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AmityImageData;
@class AmityUser;
@class AmityLiveStreamURLInfo;
@class AmityLiveVideoRecordingData;
@class AmityImageData;
@class EkoFileModel;

typedef NS_ENUM(NSUInteger, AmityStreamStatus);

NS_ASSUME_NONNULL_BEGIN

/// AmityStream provides essential data describing a single stream.
__attribute__((objc_subclassing_restricted))
@interface AmityStream : NSObject

/// The unique of stream object.
@property (nonnull, strong, readonly, nonatomic) NSString *streamId;

/// The title of stream object.
@property (nullable, strong, readonly, nonatomic) NSString *title;

/// The description of stream object.
@property (nullable, strong, readonly, nonatomic) NSString *streamDescription;

/// The status of this stream.
@property (assign, readonly, nonatomic) AmityStreamStatus status;

/// This flag is `true` if the stream is deleted.
@property (assign, readonly, nonatomic) BOOL isDeleted;

/// The status of this stream.
@property (nonnull, strong, readonly, nonatomic) NSString *resolution;

/// Meta data of the stream.
@property (nonnull, strong, readonly, nonatomic) NSDictionary<NSString *, id> *meta;

/// The time when the stream was created.
@property (nonnull, strong, readonly, nonatomic) NSDate *createdAt;

/// The last time when the stream is updated.
@property (nullable, strong, readonly, nonatomic) NSDate *updatedAt;

/// The user who created this stream.
@property (nullable, strong, readonly, nonatomic) AmityUser *user;

/// The thumbnail of this stream.
@property (nullable, strong, readonly, nonatomic) AmityImageData *thumbnail;

/// The RTMP url for streamer side. You use this url to broadcast live video to RTMP server.
///
/// This url is intended for one session streaming. After the streaming is ended, you cannot broadcast again using the same url.
/// To broadcast another session, you must obtain the new streamUrl by creating a new stream object.
///
@property (nullable, strong, readonly, nonatomic) AmityLiveStreamURLInfo *streamerUrl;

/// The RTMP url for watcher side. You use this url to play live video, that is broadcasted from streamerUrl of the same AmityStream instance.
///
@property (nullable, strong, readonly, nonatomic) AmityLiveStreamURLInfo *watcherUrl;

/// The RTMP url for watcher side. You use this url to play live video, that is broadcasted from streamerUrl of the same AmityStream instance.
///
@property (nonnull, strong, readonly, nonatomic) NSArray<AmityLiveVideoRecordingData *> *recordingData;

// Helper methods

+ (nonnull NSString *)valueFromStreamStatus:(AmityStreamStatus)status;

+ (AmityStreamStatus)streamStatusFromValue:(nonnull NSString *)status;

#pragma mark - Prevent default initializer

/// Block call of `init` and `new` because this object cannot be created directly
- (instancetype)init NS_UNAVAILABLE;

/// Block call of `init` and `new` because this object cannot be created directly
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
