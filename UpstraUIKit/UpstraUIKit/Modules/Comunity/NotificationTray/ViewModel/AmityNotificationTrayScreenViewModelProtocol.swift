//
//  AmityNotificationTrayScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import AmitySDK

protocol AmityNotificationTrayScreenViewModelDataSource {
    func numberOfItems() -> Int
    func item(at indexPath: IndexPath) -> NotificationTray?
    func loadMore()
}

protocol AmityNotificationTrayScreenViewModelDelegate: AnyObject {
    func screenViewModelDidUpdateData(_ viewModel: AmityNotificationTrayScreenViewModel)
}

protocol AmityNotificationTrayScreenViewModelAction {}

protocol AmityNotificationTrayScreenViewModelType: AmityNotificationTrayScreenViewModelAction, AmityNotificationTrayScreenViewModelDataSource {
    var action: AmityNotificationTrayScreenViewModelAction { get }
    var dataSource: AmityNotificationTrayScreenViewModelDataSource { get }
    var delegate: AmityNotificationTrayScreenViewModelDelegate? { get set }
}

extension AmityNotificationTrayScreenViewModelType {
    var action: AmityNotificationTrayScreenViewModelAction { return self }
    var dataSource: AmityNotificationTrayScreenViewModelDataSource { return self }
}
