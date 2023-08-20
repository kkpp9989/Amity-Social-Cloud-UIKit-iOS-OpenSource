//
//  ONEKrungthaiCustomTheme.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 28/6/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import UIKit

class ONEKrungthaiCustomTheme {
    
    var viewController: UIViewController
    
    static let defaultIconBarItemWidth: CGFloat = 32.0
    static let defaultIconBarItemHeight: CGFloat = 32.0
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    // MARK: Background of navigation bar
    public func setBackgroundApp(index: Int) {
        // Get gradient background
        let background: UIImage? = getGradientImageForBackgroundApp()
        
        // Set background to UIImageView and add its to subview to index selected
        let backgroundImageView = UIImageView(image: background)
        viewController.view.insertSubview(backgroundImageView, at: index)
    }
    
    public func setBackgroundNavigationBar() {
        // Get gradient background
        let background: UIImage? = getGradientImageForBackgroundNavigationBar()
        
        if #available(iOS 15.0, *) {
            // Create custom navigation bar setting
            let navBarAppearance = UINavigationBarAppearance()
    
            // Use an extension to create an image from the gradient layer
            navBarAppearance.backgroundImage = background
    
            // Apply the navigation bar appearance to the navigation bar
            viewController.navigationController?.navigationBar.standardAppearance = navBarAppearance
            viewController.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        } else { // For iOS 14 or lower
            viewController.navigationController?.navigationBar.isTranslucent = false
            viewController.navigationController?.navigationBar.setBackgroundImage(background, for: .default)
        }
    }
    
    public func clearNavigationBarSetting() {
        if #available(iOS 15.0, *) {
            // Create custom navigation bar setting
            let navBarAppearance = UINavigationBarAppearance()
    
            // Set clear background
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.backgroundImage = UIImage()
            navBarAppearance.backgroundColor = .clear
            navBarAppearance.shadowColor = .clear
            navBarAppearance.shadowImage = UIImage()
    
            // Apply the navigation bar appearance to the navigation bar
            viewController.navigationController?.navigationBar.standardAppearance = navBarAppearance
            viewController.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        } else { // For iOS 14 or lower
            viewController.navigationController?.navigationBar.isTranslucent = true
            viewController.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        }
    }
    
    private func getGradientImageForBackgroundApp() -> UIImage? {
        let gradientLayer = CAGradientLayer()
        // Customize the colors as per your preference
        gradientLayer.colors = [
            UIColor(red: CGFloat(179.0/255.0), green: CGFloat(234.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.3).cgColor, // #B2EAFF with alpha 30%
            UIColor(red: CGFloat(128.0/255.0), green: CGFloat(220.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.7).cgColor] // #80DCFF with alpha 70%
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = viewController.view.bounds
        gradientLayer.locations = [0.1, 1.0]
        
        // Get height and width
        let fullScreenHeight = viewController.view.bounds.height
        let fullScreenWidth = viewController.navigationController?.navigationBar.bounds.width ?? 0

        // Adjust the frame to extend beyond the navigation bar by 50 pixels
        gradientLayer.frame = CGRect(x: 0, y: -fullScreenHeight, width: fullScreenWidth, height: fullScreenHeight)
        
        // Create image
        return gradientLayer.createImage()
    }
    
    private func getGradientImageForBackgroundNavigationBar() -> UIImage? {
        let gradientLayer = CAGradientLayer()
        // Customize the colors as per your preference
        gradientLayer.colors = [
            UIColor(red: CGFloat(179.0/255.0), green: CGFloat(234.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.3).cgColor, // #B2EAFF with alpha 30%
            UIColor(red: CGFloat(128.0/255.0), green: CGFloat(220.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.7).cgColor] // #80DCFF with alpha 70%
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = viewController.navigationController?.navigationBar.bounds ?? CGRect.zero
        
        let navigationBarHeight = viewController.navigationController?.navigationBar.frame.height ?? 0
        let extendedHeight = navigationBarHeight + 50

        gradientLayer.locations = [0.1, 1.0]

        // Adjust the frame to extend beyond the navigation bar by 50 pixels
        if #available(iOS 15.0, *) {
            gradientLayer.frame = CGRect(x: 0, y: -extendedHeight, width: viewController.navigationController?.navigationBar.bounds.width ?? 0, height: extendedHeight)
        } else { // For iOS 14 or lower
            // Calculate the extended height
            let extendedHeight = UIApplication.shared.statusBarFrame.height + (viewController.navigationController?.navigationBar.bounds.height ?? 0)

            // Adjust the frame of the gradient layer
            gradientLayer.frame = CGRect(x: 0, y: -extendedHeight, width: viewController.view.bounds.width, height: extendedHeight)
        }
        
        // Create image
        return gradientLayer.createImage()
    }
    
    // MARK: Icon of navigation bar
    public static func groupButtonsToUIBarButtonItem(buttons: [UIButton]) -> UIBarButtonItem {
        let customStackView = UIStackView.init(arrangedSubviews: buttons)
        customStackView.distribution = .equalSpacing
        customStackView.axis = .horizontal
        customStackView.alignment = .center
        customStackView.spacing = 12
        
        return UIBarButtonItem(customView: customStackView)
    }
}

extension CALayer {
    func createImage() -> UIImage? {
        UIGraphicsBeginImageContext(self.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            self.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
}
