//
//  AmityToastView.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 5/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class ToastView: UIView {
    static let shared = ToastView()
    
    private var toastLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    private init() {
        super.init(frame: CGRect.zero)
        setupToastView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupToastView() {
        self.backgroundColor = UIColor.black.withAlphaComponent(1.0)
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        addSubview(toastLabel)
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        toastLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        toastLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        toastLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
    }
    
    func showToast(message: String, duration: TimeInterval = 3.0, in window: UIWindow) {
        DispatchQueue.main.async { [self] in
            toastLabel.text = message
            self.alpha = 1
            
            window.addSubview(self)
            self.translatesAutoresizingMaskIntoConstraints = false
            self.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
            self.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -40).isActive = true
            self.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 16).isActive = true
            self.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -16).isActive = true
            
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }
}
