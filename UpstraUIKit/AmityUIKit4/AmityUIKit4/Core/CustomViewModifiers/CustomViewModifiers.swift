//
//  CustomViewModifiers.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 1/25/24.
//

import SwiftUI

// MARK: View

extension View {
    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    ///
    ///     Text("Label")
    ///         .isHidden(true, remove: false)
    ///
    /// Example for complete removal:
    ///
    ///     Text("Label")
    ///         .isHidden(true)
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///   - remove: Boolean value indicating whether or not to remove the view.
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = true) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: Button

private func withFeedback(
  _ style: UIImpactFeedbackGenerator.FeedbackStyle,
  _ action: @escaping () -> Void
) -> () -> Void {
  { () in
      ImpactFeedbackGenerator.impactFeedback(style: style)
      action()
  }
}

extension Button {
    init(
        feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
      ) {
        self.init(action: withFeedback(feedbackStyle, action), label: label)
      }
}