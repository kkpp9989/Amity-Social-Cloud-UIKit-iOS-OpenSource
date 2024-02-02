//
//  AmityPreviewSelectedFromPickerScreenViewModelProtocol.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 1/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

protocol AmityPreviewSelectedFromPickerScreenViewModelDelegate: AnyObject {
    func screenViewModelDidSendBroadcastMessage(isSuccess: Bool)
}

protocol AmityPreviewSelectedFromPickerScreenViewModelDataSource {
    func numberOfDatas() -> Int
    func data(at row: Int) -> AmitySelectMemberModel?
}

protocol AmityPreviewSelectedFromPickerScreenViewModelAction {
    func sendBroadcastMessage()
}

protocol AmityPreviewSelectedFromPickerScreenViewModelType: AmityPreviewSelectedFromPickerScreenViewModelAction, AmityPreviewSelectedFromPickerScreenViewModelDataSource {
    var action: AmityPreviewSelectedFromPickerScreenViewModelAction { get }
    var dataSource: AmityPreviewSelectedFromPickerScreenViewModelDataSource { get }
    var delegate: AmityPreviewSelectedFromPickerScreenViewModelDelegate? { get set }
}

extension AmityPreviewSelectedFromPickerScreenViewModelType {
    var action: AmityPreviewSelectedFromPickerScreenViewModelAction { return self }
    var dataSource: AmityPreviewSelectedFromPickerScreenViewModelDataSource { return self }
}
