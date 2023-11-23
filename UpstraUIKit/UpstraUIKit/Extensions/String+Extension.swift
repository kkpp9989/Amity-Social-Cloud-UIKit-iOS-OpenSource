//
//  String+Extension.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 4/6/2563 BE.
//  Copyright © 2563 Amity Communication. All rights reserved.
//

import UIKit

extension String {
    /// Apply to bold text
    /// - Parameters:
    ///   - listString: List string for make to bold
    ///   - color: normal color and bold color
    ///   - font: normal font and bold font
    /// - Returns: NSAttributedString
    func applyBold(with listString: [String],
                       color: UIColor,
                       font: (normal: UIFont, bold: UIFont)) -> NSAttributedString {
        let boldString = NSMutableAttributedString(string: self, attributes: [.foregroundColor: color,
                                                                              .font: font.normal])
        for index in 0..<listString.count {
            boldString.addAttributes([.font: font.bold], range: (self as NSString).range(of: listString[index]))
        }
        return boldString
    }
    
    public var localizedString: String {
            return NSLocalizedString(self, tableName: "AmityLocalizable", bundle: AmityUIKitManager.bundle, value: "", comment: "")
    }
    
    public func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    
        return ceil(boundingBox.height)
    }

    public func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
    
    public func numberOfLines(withConstrainedWidth width: CGFloat, font: UIFont) -> Int {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        
        let textStorage = NSTextStorage(string: self, attributes: [NSAttributedString.Key.font: font])
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: constraintRect)
        layoutManager.addTextContainer(textContainer)
        
        var numberOfLines = 0
        
        layoutManager.enumerateLineFragments(forGlyphRange: NSMakeRange(0, layoutManager.numberOfGlyphs)) { (rect, usedRect, textContainer, glyphRange, stop) in
            numberOfLines += 1
        }
        
        return numberOfLines
    }
    
}
