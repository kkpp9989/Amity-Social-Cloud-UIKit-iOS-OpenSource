//
//  AmityMessagesSearchScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityMessagesSearchScreenViewModelDelegate: AnyObject {
    func screenViewModelDidSearch(_ viewModel: AmityMessagesSearchScreenViewModelType)
    func screenViewModelDidClearText(_ viewModel: AmityMessagesSearchScreenViewModelType)
    func screenViewModelDidSearchNotFound(_ viewModel: AmityMessagesSearchScreenViewModelType)
    func screenViewModel(_ viewModel: AmityMessagesSearchScreenViewModelType, loadingState: AmityLoadingState)
}

protocol AmityMessagesSearchScreenViewModelDataSource {
    func numberOfKeyword() -> Int
    func item(at indexPath: IndexPath) -> AmitySDK.AmityMessage?
}

protocol AmityMessagesSearchScreenViewModelAction {
    func search(withText text: String?)
    func loadMore()
}

protocol AmityMessagesSearchScreenViewModelType: AmityMessagesSearchScreenViewModelAction, AmityMessagesSearchScreenViewModelDataSource {
    var delegate: AmityMessagesSearchScreenViewModelDelegate? { get set }
    var action: AmityMessagesSearchScreenViewModelAction { get }
    var dataSource: AmityMessagesSearchScreenViewModelDataSource { get }
}

extension AmityMessagesSearchScreenViewModelType {
    var action: AmityMessagesSearchScreenViewModelAction { return self }
    var dataSource: AmityMessagesSearchScreenViewModelDataSource { return self }
}
