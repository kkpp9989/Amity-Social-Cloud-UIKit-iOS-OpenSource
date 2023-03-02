//
//  EkoCommunityCategoryModel.h
//  AmitySDK
//
//  Created by Nishan Niraula on 7/20/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AmitySDK/EkoRealmModel.h>

NS_ASSUME_NONNULL_BEGIN

@class EkoFileModel;

@interface EkoCommunityCategoryModel : EkoRealmModel

@property (nonatomic, strong) NSString *categoryId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *avatarFileId;
@property (assign, nonatomic) BOOL isDeleted;
@property (nullable, nonatomic) EkoFileModel *avatar;

@end

NS_ASSUME_NONNULL_END

RLM_COLLECTION_TYPE(EkoCommunityCategoryModel);
