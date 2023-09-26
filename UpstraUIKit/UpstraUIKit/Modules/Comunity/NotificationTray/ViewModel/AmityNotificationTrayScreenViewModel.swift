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

    func updateReadTray() {
        let serviceRequest = RequestGetNotification()
        serviceRequest.requestNotificationLastRead() { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func getCurrentTimestamp() -> Int {
        // Get the current date and time in the user's local time zone
        let currentDate = Date()

        // Create a DateFormatter to specify the time zone as local
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        // Format the current date as a Unix timestamp string
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestampString = dateFormatter.string(from: currentDate)

        // Convert the timestamp string to a Date object
        if let timestampDate = dateFormatter.date(from: timestampString) {
            // Get the Unix timestamp as an integer (number of seconds since 1970)
            let unixTimestamp = Int(timestampDate.timeIntervalSince1970)
            return unixTimestamp
        } else {
            // Return a default value or handle the error as needed
            return Int(currentDate.timeIntervalSince1970)
        }
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
//        fetchData()
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
