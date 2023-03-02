//
//  EkoStreamModel.h
//  AmitySDK
//
//  Created by Nutchaphon Rewik on 22/9/2563 BE.
//  Copyright © 2563 amity. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EkoFileModel;
@class EkoUserModel;

#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

/// Stream Realm Model. Do not access this class directly. Use `AmityStream` class instead.
@interface EkoStreamModel : EkoRealmModel

@property (nonnull) NSString *streamId;

@property (nullable) NSString *title;
@property (nullable) NSString *streamDescription;

@property (nullable) NSString *status;

@property (nullable) NSString *resolution;

@property (nonnull) NSString *userId;
@property (nullable) NSString *thumbnailFileId;

@property (nullable) NSData *streamerUrlData;
@property (nullable) NSData *watcherUrlData;

@property (nullable) NSData *recordingsData;

@property (nullable) EkoUserModel *userModel;
@property (nullable) EkoFileModel *thumbnailModel;

@property BOOL isDeleted;
@property BOOL disposeLocally;

@end

NS_ASSUME_NONNULL_END
