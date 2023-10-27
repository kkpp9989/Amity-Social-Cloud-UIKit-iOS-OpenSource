//
//  AmityTempSendImageMessageData.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 26/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityTempSendImageMessageData {
    static let shared = AmityTempSendImageMessageData()
    private(set) var data: [String: UIImage] = [:]
    
    func add(image: UIImage, fileURLString: String) {
        data[fileURLString] = image
    }
    
    func remove(fileURLString: String) {
        data.removeValue(forKey: fileURLString)
    }
}
