//
//  DateFormatter+Extension.swift
//  UpstraUIKit
//
//  Created by Nontapat Siengsanor on 27/8/2563 BE.
//  Copyright © 2563 Upstra. All rights reserved.
//

import UIKit

extension DateFormatter {
    
    static func releativeDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
    
}
