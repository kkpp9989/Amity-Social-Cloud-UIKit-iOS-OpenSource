//
//  AmityAttributedString.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 15/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit

final class AmityAttributedString {
    private var fullText: String = ""
    private var boldText: [String] = []
    private var boldFont: UIFont = UIFont.systemFont(ofSize: 14)
    private var normalFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
    private var normalColor: UIColor = .black
    private var boldColor: UIColor = .black
    
    @discardableResult
    func setTitle(_ text: String) -> AmityAttributedString {
        fullText = text
        return self
    }
    
    @discardableResult
    func setBoldText(for text: [String]) -> AmityAttributedString {
        boldText = text
        return self
    }
    
    @discardableResult
    func setBoldFont(for font: UIFont) -> AmityAttributedString {
        boldFont = font
        return self
    }
    
    @discardableResult
    func setNormalFont(for font: UIFont) -> AmityAttributedString {
        normalFont = font
        return self
    }
    
    @discardableResult
    func setNormalColor(for color: UIColor) -> AmityAttributedString {
        self.normalColor = color
        return self
    }
    
    @discardableResult
    func setBoldColor(for color: UIColor) -> AmityAttributedString {
        self.boldColor = color
        return self
    }
    
    func build() -> NSAttributedString {
        return fullText.applyBold(with: boldText, boldColor: boldColor, normalColor: normalColor, font: (normalFont, boldFont))
    }
}
