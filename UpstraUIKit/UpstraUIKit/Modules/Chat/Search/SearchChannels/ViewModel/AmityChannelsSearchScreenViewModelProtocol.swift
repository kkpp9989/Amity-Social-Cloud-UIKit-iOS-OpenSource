//
//  AmityChannelsSearchScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import AmitySDK

protocol AmityChannelsSearchScreenViewModelDelegate: AnyObject {
    func screenViewModelDidSearch(_ viewModel: AmityChannelsSearchScreenViewModelType)
    func screenViewModelDidClearText(_ viewModel: AmityChannelsSearchScreenViewModelType)
    func screenViewModelDidSearchNotFound(_ viewModel: AmityChannelsSearchScreenViewModelType)
    func screenViewModel(_ viewModel: AmityChannelsSearchScreenViewModelType, loadingState: AmityLoadingState)
}

protocol AmityChannelsSearchScreenViewModelDataSource {
    func numberOfKeyword() -> Int
    func item(at indexPath: IndexPath) -> Channel?
}

protocol AmityChannelsSearchScreenViewModelAction {
    func search(withText text: String?)
    func loadMore()
    func join(withModel model: Channel)
    func clearData()
}

protocol AmityChannelsSearchScreenViewModelType: AmityChannelsSearchScreenViewModelAction, AmityChannelsSearchScreenViewModelDataSource {
    var delegate: AmityChannelsSearchScreenViewModelDelegate? { get set }
    var action: AmityChannelsSearchScreenViewModelAction { get }
    var dataSource: AmityChannelsSearchScreenViewModelDataSource { get }
}

extension AmityChannelsSearchScreenViewModelType {
    var action: AmityChannelsSearchScreenViewModelAction { return self }
    var dataSource: AmityChannelsSearchScreenViewModelDataSource { return self }
}
