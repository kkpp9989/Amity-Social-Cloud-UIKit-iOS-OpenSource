//
//  AmityCommunityHomePageViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 18/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

public class AmityCommunityHomePageViewController: AmityPageViewController {
    
    // MARK: - Properties
    public let newsFeedVC = AmityNewsfeedViewController.make()
    public let exploreVC = AmityCommunityExplorerViewController.make()
    
    private init() {
        super.init(nibName: AmityCommunityHomePageViewController.identifier, bundle: AmityUIKitManager.bundle)
        // original
//        title = AmityLocalizedStringSet.communityHomeTitle.localizedString
        // Custom for ONE Krungthai -> Set title of navigation bar to nil and add title to left navigation item at setupNavigationBar() instead
        title = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
    }
    
    public static func make() -> AmityCommunityHomePageViewController {
        return AmityCommunityHomePageViewController()
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        newsFeedVC.pageTitle = AmityLocalizedStringSet.newsfeedTitle.localizedString
        exploreVC.pageTitle = AmityLocalizedStringSet.exploreTitle.localizedString
        return [newsFeedVC, exploreVC]
    }
    
    // MARK: - Setup view
    
    private func setupNavigationBar() {
        // Search Button (Right)
        let searchItem = UIBarButtonItem(image: AmityIconSet.iconSearch, style: .plain, target: self, action: #selector(searchTap))
        searchItem.tintColor = AmityColorSet.base
        navigationItem.rightBarButtonItem = searchItem
        
        // Title navigation bar for community home (Left)
        // Title
        let title = UILabel()
        title.text = AmityLocalizedStringSet.communityHomeTitle.localizedString
        title.font = AmityFontSet.headerLine
        // Back button (Refer default leftBarButtonItem from AmityViewController)
        let backButton = UIBarButtonItem(image: AmityIconSet.iconBack, style: .plain, target: self, action: #selector(didTapLeftBarButton))
        backButton.tintColor = AmityColorSet.base
        // Add all component to left navigation item
        navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: title)] // Back button, Title of naviagation bar
        
        // Setup custom navigation bar theme for ONE Krungthai
        setupGradient()
    }
}

// MARK: - Action
private extension AmityCommunityHomePageViewController {
    @objc func searchTap() {
        let searchVC = AmitySearchViewController.make()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
    private func setupGradient() {
        let gradientLayer = CAGradientLayer()
        // Customize the colors as per your preference
        gradientLayer.colors = [
            UIColor(red: CGFloat(179.0/255.0), green: CGFloat(234.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.3).cgColor, // #B2EAFF with alpha 30%
            UIColor(red: CGFloat(128.0/255.0), green: CGFloat(220.0/255.0), blue: CGFloat(255.0/255.0), alpha: 0.7).cgColor] // #80DCFF with alpha 70%
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = navigationController?.navigationBar.bounds ?? CGRect.zero
        gradientLayer.locations = [0.1, 1.0]
        
        let navigationBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let extendedHeight = navigationBarHeight + 50

        // Adjust the frame to extend beyond the navigation bar by 50 pixels
        gradientLayer.frame = CGRect(x: 0, y: -extendedHeight, width: navigationController?.navigationBar.bounds.width ?? 0, height: extendedHeight)
        
        //  Navigation bar color set
        let navBarAppearance = UINavigationBarAppearance()
        // Use an extension to create an image from the gradient layer
        navBarAppearance.backgroundImage = gradientLayer.createImage()

        // Customize other appearance properties as needed, such as title text color, button colors, etc.
        let titleTextAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.black] // Customize the text color

        // Set the title text attributes for the navigation bar
        navBarAppearance.titleTextAttributes = titleTextAttributes

        // Apply the navigation bar appearance to the navigation bar
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
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
