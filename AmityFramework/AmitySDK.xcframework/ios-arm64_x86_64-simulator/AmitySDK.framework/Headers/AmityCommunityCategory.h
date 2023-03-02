//
//  AmityCommunityCategory.h
//  AmitySDK
//
//  Created by Nishan Niraula on 7/20/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoModelProtocol.h>

@class AmityImageData;

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
/// Instance of category of community. A community can belong to multiple categories.
@interface AmityCommunityCategory : NSObject <EkoModelProtocol>

/// Id of the category
@property (nonatomic, strong) NSString *categoryId;

/// Name of the category
@property (nonatomic, strong) NSString *name;

/// File id for avatar of the category
@property (nonatomic, strong) NSString *avatarFileId;

/// Date when this Category was created
@property (strong, nonatomic) NSDate *createdAt;

/// Date when this Category was last updated
@property (strong, nonatomic) NSDate *updatedAt;

/// The avatar model of the community category
@property (nullable, strong, readonly, nonatomic) AmityImageData *avatar;

/// If its the deleted category
@property (assign, nonatomic) BOOL isDeleted;

@end

NS_ASSUME_NONNULL_END
