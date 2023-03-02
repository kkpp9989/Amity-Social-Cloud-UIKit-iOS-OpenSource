//
//  EkoCollectionTransactionDelegate.h
//  AmitySDK
//
//  Created by Nishan Niraula on 11/4/20.
//  Copyright © 2020 amity. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EkoCollectionTransactionDelegate <NSObject>

// When we receive empty results from server, there would be no changes in the realm. As a result
// notification will not get triggered i.e observer block doesnot get called. In most of the cases
// there won't be any issue with this. But there are some cases where we want observer block to get
// called even if there are no results. For example:
//
// User search for "abc" and get 10 results. Now user search from "abcd" but there are no results.
// In this case observer block doesnot get called as no changes are made to realm. But we want
// user to know that there are no results.
//
// So this method helps transaction to tell collection that we received empty results from server.
// In turn collection can notify user with empty results.
- (void)didReceiveEmptyResults:(BOOL)shouldNotify;
@end
