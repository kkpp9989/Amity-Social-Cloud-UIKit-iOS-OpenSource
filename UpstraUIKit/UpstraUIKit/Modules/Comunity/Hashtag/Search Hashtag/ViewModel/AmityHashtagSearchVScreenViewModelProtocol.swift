//
//  AmityHashtagSearchVScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

protocol AmityHashtagSearchScreenViewModelDelegate: AnyObject {
    func screenViewModelDidSearch(_ viewModel: AmityHashtagSearchScreenViewModelType)
    func screenViewModelDidClearText(_ viewModel: AmityHashtagSearchScreenViewModelType)
    func screenViewModelDidSearchNotFound(_ viewModel: AmityHashtagSearchScreenViewModelType)
    func screenViewModel(_ viewModel: AmityHashtagSearchScreenViewModelType, loadingState: AmityLoadingState)
}

protocol AmityHashtagSearchScreenViewModelDataSource {
    func numberOfKeyword() -> Int
    func item(at indexPath: IndexPath) -> AmityHashtagModel?
}

protocol AmityHashtagSearchScreenViewModelAction {
    func search(withText text: String?)
    func loadMore()
}

protocol AmityHashtagSearchScreenViewModelType: AmityHashtagSearchScreenViewModelAction, AmityHashtagSearchScreenViewModelDataSource {
    var delegate: AmityHashtagSearchScreenViewModelDelegate? { get set }
    var action: AmityHashtagSearchScreenViewModelAction { get }
    var dataSource: AmityHashtagSearchScreenViewModelDataSource { get }
}

extension AmityHashtagSearchScreenViewModelType {
    var action: AmityHashtagSearchScreenViewModelAction { return self }
    var dataSource: AmityHashtagSearchScreenViewModelDataSource { return self }
}
