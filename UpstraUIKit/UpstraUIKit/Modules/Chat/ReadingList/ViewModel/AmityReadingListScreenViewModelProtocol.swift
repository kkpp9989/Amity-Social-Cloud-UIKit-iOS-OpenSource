//
//  AmityReadingListScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityReadingListScreenViewModelDelegate: AnyObject {
    func screenViewModelDidFetchSuccess(_ viewModel: AmityReadingListScreenViewModelType)
    func screenViewModelDidFetchNotFound(_ viewModel: AmityReadingListScreenViewModelType)
    func screenViewModel(_ viewModel: AmityReadingListScreenViewModelType, loadingState: AmityLoadingState)
}

protocol AmityReadingListScreenViewModelDataSource {
    func numberOfKeyword() -> Int
    func item(at indexPath: IndexPath) -> AmityUserModel?
}

protocol AmityReadingListScreenViewModelAction {
    func fetchData()
    func loadMore()
    func clearData()
}

protocol AmityReadingListScreenViewModelType: AmityReadingListScreenViewModelAction, AmityReadingListScreenViewModelDataSource {
    var delegate: AmityReadingListScreenViewModelDelegate? { get set }
    var action: AmityReadingListScreenViewModelAction { get }
    var dataSource: AmityReadingListScreenViewModelDataSource { get }
}

extension AmityReadingListScreenViewModelType {
    var action: AmityReadingListScreenViewModelAction { return self }
    var dataSource: AmityReadingListScreenViewModelDataSource { return self }
}
