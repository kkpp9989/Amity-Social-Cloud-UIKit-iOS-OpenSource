//
//  AmityNotificationTrayScreenViewModel.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityNotificationTrayScreenViewModel: AmityNotificationTrayScreenViewModelType {
    
    weak var delegate: AmityNotificationTrayScreenViewModelDelegate?
    
    private var collectionData: AmityNotificationTrayModel?
    
    private var page: Int = 1
    
    init() {}
    
    func fetchData() {
        let timeStamp = getCurrentTimestamp()
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationHistory(timeStamp) { [self] result in
            switch result {
            case .success(let dataResponse):
                collectionData = dataResponse
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
        }
    }

    private func updateReadTray() {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationLastRead() { [self] result in
            switch result {
            case .success(_):
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
        }
    }
    
    private func getCurrentTimestamp() -> Int {
        let timestamp = Int(Date().timeIntervalSince1970)
        return timestamp
    }
    
    // MARK: - Data Source
    
    func numberOfItems() -> Int {
        return collectionData?.data.count ?? 0
    }
    
    func item(at indexPath: IndexPath) -> NotificationTray? {
        return collectionData?.data[indexPath.row]
    }
    
    func loadMore() {
        page += 1
        fetchData()
    }
    
    func updateReadItem(model: NotificationTray) {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationRead(model.verb, targetId: model.targetID) { [self] result in
            switch result {
            case .success(_):
                delegate?.screenViewModelDidUpdateData(self)
            case .failure(let error):
                print(error)
                delegate?.screenViewModelDidUpdateData(self)
            }
        }
    }
    
}
