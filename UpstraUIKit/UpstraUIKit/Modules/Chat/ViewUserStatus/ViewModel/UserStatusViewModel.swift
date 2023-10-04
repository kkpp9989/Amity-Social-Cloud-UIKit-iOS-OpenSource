//
//  UserStatusViewModel.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/5/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import Foundation
import AmitySDK

final class UserStatusViewModel {
    
    var typeSelect: AmityUserStatus.StatusType = AmityUIKitManagerInternal.shared.userStatus
    
    init() {
        
    }
    
}

// MARK: - AmitySDK Update Status
extension UserStatusViewModel {
    
   public func setStatus() {
        
    }
    
}

// MARK: - TableView DataIndex
extension UserStatusViewModel {
    
   public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfRowsInSection() -> Int {
        return AmityUserStatus.StatusType.allCases.count
    }
    
    public func heightForRowAt() -> CGFloat {
        return 48
    }
    
    public func cellForRowAtData(_ indexPath: IndexPath) -> String {
        switch AmityUserStatus.StatusType(rawValue: indexPath.row) {
        case .some(.AVAILABLE):
            return "Available"
        case .some(.DO_NOT_DISTURB):
            return "Do not disturb"
        case .some(.IN_THE_OFFICE):
            return "In the office"
        case .some(.WORK_FROM_HOME):
            return "Work from home"
        case .some(.IN_A_MEETING):
            return "In a meeting"
        case .some(.ON_LEAVE):
            return "On leave"
        case .some(.OUT_SICK):
            return "Out sick"
        case .some(.unknown):
            return ""
        case .none:
            return ""
        }
    }
    
    public func isSelectStatus(_ indexPath: IndexPath) -> Bool {
        return indexPath.row != typeSelect.rawValue
    }
    
}
