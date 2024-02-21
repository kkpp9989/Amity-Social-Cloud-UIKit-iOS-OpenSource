//
//  CustomEvenHandle.swift
//  AmityUIKitLiveStream
//
//  Created by kk on 20/2/2567 BE.
//

import Foundation
import AmityUIKit
import UIKit

open class AmityLiveEventHandler:AmityEventHandler {
    
    static var shared = AmityEventHandler()
   
}

public final class AmityLiveManager {
    
    private init() { }
    
    public static func set(eventHandler: AmityEventHandler) {
        AmityLiveEventHandler.shared = eventHandler
    }
}
