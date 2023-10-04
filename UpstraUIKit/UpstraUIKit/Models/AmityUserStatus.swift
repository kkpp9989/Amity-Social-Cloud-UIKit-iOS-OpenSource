//
//  AmityStatusUser.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/5/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import Foundation

struct AmityUserStatus {
    
    enum StatusType: Int, CaseIterable {
        case AVAILABLE = 0, DO_NOT_DISTURB ,IN_THE_OFFICE ,WORK_FROM_HOME ,IN_A_MEETING ,ON_LEAVE ,OUT_SICK,unknown
    }
    
    func mapTypeToAmitySDK(_ statusType: StatusType) -> String {
        switch statusType {
        case .AVAILABLE:
            return "available"
        case .DO_NOT_DISTURB:
            return "do_not_disturb"
        case .IN_THE_OFFICE:
            return "in_the_office"
        case .WORK_FROM_HOME:
            return "work_from_home"
        case .IN_A_MEETING:
            return "in_a_meeting"
        case .ON_LEAVE:
            return "on_leave"
        case .OUT_SICK:
            return "out_sick"
        case .unknown:
            return ""
        }
    }
    
    func mapAmitySDKToType(_ stringType: String) -> StatusType {
        switch stringType {
        case "available":
            return .AVAILABLE
        case "do_not_disturb":
            return .DO_NOT_DISTURB
        case "in_the_office":
            return .IN_THE_OFFICE
        case "work_from_home":
            return .WORK_FROM_HOME
        case "in_a_meeting":
            return .IN_A_MEETING
        case "on_leave":
            return .ON_LEAVE
        case "out_sick":
            return .OUT_SICK
        default:
            return .unknown
        }
    }
    
}
