//
//  AmityColorSet.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 15/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit

struct AmityColorSet {
    
    static var primary: UIColor {
        return AmityThemeManager.currentTheme.primary
    }
    static var secondary: UIColor {
        return AmityThemeManager.currentTheme.secondary
    }
    static var alert: UIColor {
        return AmityThemeManager.currentTheme.alert
    }
    static var highlight: UIColor {
        return AmityThemeManager.currentTheme.highlight
    }
    static var base: UIColor {
        return AmityThemeManager.currentTheme.base
    }
    static var baseInverse: UIColor {
        return AmityThemeManager.currentTheme.baseInverse
    }
    static var messageBubble: UIColor {
        return AmityThemeManager.currentTheme.messageBubble
    }
    static var messageBubbleInverse: UIColor {
        return AmityThemeManager.currentTheme.messageBubbleInverse
    }
    
    static var backgroundColor: UIColor {
        return UIColor.white
    }
    
    static var dnaSangsun: UIColor {
        return UIColor(hex: "#FFC104")
    }
    
    static var dnaSatsue: UIColor {
        return UIColor(hex: "#002FFF")
    }
    
    static var dnaSamakki: UIColor {
        return UIColor(hex: "#04873F")
    }
    
    static var dnaSumrej: UIColor {
        return UIColor(hex: "#FE0202")
    }
    
    static var dnaSangkom: UIColor {
        return UIColor(hex: "#FC7111")
    }
    
    static var dnaLike: UIColor {
        return UIColor(hex: "#0080BD")
    }
    
    static var dnaLove: UIColor {
        return UIColor(hex: "#EC4545")
    }
}
