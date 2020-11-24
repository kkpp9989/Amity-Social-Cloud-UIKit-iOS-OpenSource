//
//  Notification+Extension.swift
//  UpstraUIKit
//
//  Created by Nontapat Siengsanor on 19/10/2563 BE.
//  Copyright © 2563 Upstra. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    struct Post {
        static let didCreate = Notification.Name("postDidCreate")
        static let didUpdate = Notification.Name("postDidUpdate")
        static let didDelete = Notification.Name("postDidDelete")
    }
    
}
