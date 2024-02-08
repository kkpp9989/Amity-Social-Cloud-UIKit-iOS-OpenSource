//
//  AmityChatHomeParentScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 8/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityChatHomeParentScreenViewModelDelegate: AnyObject {
    func screenViewModelDidGetCreateBroadcastMessagePermission(_ viewModel: AmityChatHomeParentScreenViewModelType, isHavePermission: Bool)
}

protocol AmityChatHomeParentScreenViewModelDatasource {
}

protocol AmityChatHomeParentScreenViewModelAction {
    func getCreateBroadcastMessagePermission()
}

protocol AmityChatHomeParentScreenViewModelType: AmityChatHomeParentScreenViewModelAction, AmityChatHomeParentScreenViewModelDatasource {
    var delegate: AmityChatHomeParentScreenViewModelDelegate? { get set }
    var action: AmityChatHomeParentScreenViewModelAction { get }
    var dataSource: AmityChatHomeParentScreenViewModelDatasource { get }
}

extension AmityChatHomeParentScreenViewModelType {
    var action: AmityChatHomeParentScreenViewModelAction { return self }
    var dataSource: AmityChatHomeParentScreenViewModelDatasource { return self }
}
