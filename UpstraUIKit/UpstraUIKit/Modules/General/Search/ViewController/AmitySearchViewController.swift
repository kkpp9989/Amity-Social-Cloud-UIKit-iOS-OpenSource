//
//  AmitySearchViewController.swift
//  AmityUIKit
//
//  Created by Hamlet on 11.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

public class AmitySearchViewController: AmityPageViewController {

    // MARK: - IBOutlet
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var searchView: UIView!
    @IBOutlet private weak var searchStackView: UIStackView!
    @IBOutlet private weak var searchIcon: UIImageView!
    
    // MARK: - Child ViewController
    private var communitiesVC = AmityCommunitySearchViewController.make(title: AmityLocalizedStringSet.communities.localizedString)
    private var membersVC = AmityMemberSearchViewController.make(title: AmityLocalizedStringSet.accounts.localizedString)
    private var hashtagVC = AmityHashtagSearchViewController.make(title: AmityLocalizedStringSet.hashtags.localizedString)
    private var postsVC = AmitySearchPostsViewController.make(title: AmityLocalizedStringSet.posts.localizedString)

    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    private let debouncer = Debouncer(delay: 0.5)

    private init() {
        super.init(nibName: AmitySearchViewController.identifier, bundle: AmityUIKitManager.bundle)
        title = ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        // Set background app for this navigation bar
        theme?.setBackgroundApp(index: 0)
        
        setupNavigationBar()
        setupSearchController()
        
        // [Custom for ONE Krungthai] Set tabbar to show when open search view
        setButtonBarHidden(hidden: false)
        
        searchTextField.becomeFirstResponder()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Clear setting navigation bar (normal) from ONE Krungthai custom theme
        theme?.clearNavigationBarSetting()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public static func make() -> AmitySearchViewController {
        return AmitySearchViewController()
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        return [communitiesVC, membersVC, hashtagVC, postsVC]
    }
    
    override func moveToViewController(at index: Int, animated: Bool = true) {
        super.moveToViewController(at: index, animated: animated)
        
        viewControllerWillMove(newIndex: index)
    }
    
    // MARK: - Setup views
    private func setupNavigationBar() {
        navigationBarType = .custom
    }
    
    private func setupSearchController() {
        searchTextField.delegate = self
        searchTextField.placeholder = AmityLocalizedStringSet.General.search.localizedString
        searchTextField.returnKeyType = .done
        searchTextField.clearButtonMode = .always
        searchTextField.setupWithoutSuggestions()
        
        searchTextField.backgroundColor = .white
        searchTextField.tintColor = AmityColorSet.base
        searchTextField.textColor = AmityColorSet.base
        searchTextField.font = AmityFontSet.body
        searchTextField.leftView?.tintColor = AmityColorSet.base.blend(.shade2)
        
        cancelButton.setTitleColor(AmityColorSet.base, for: .normal)
        cancelButton.titleLabel?.font = AmityFontSet.body
        
        searchIcon.image = AmityIconSet.iconSearch?.withRenderingMode(.alwaysTemplate)
        searchIcon.tintColor = AmityColorSet.base.blend(.shade1)
        
        searchView.backgroundColor = .white
        searchView.layer.cornerRadius = 4
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        handleSearch(with: nil)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        debouncer.run {
//            print("[Search] textFieldEditingChanged| text: \(sender.text ?? "")")
            self.setButtonBarHidden(hidden: false)
        }
    }
}

private extension AmitySearchViewController {
    func handleSearch(with key: String?) {
        if viewControllers[currentIndex] == communitiesVC {
            communitiesVC.search(with: key)
        } else if viewControllers[currentIndex] == hashtagVC {
            hashtagVC.search(withText: key)
        } else if viewControllers[currentIndex] == postsVC {
            postsVC.fetchPosts(keyword: searchTextField.text ?? "")
        } else {
            membersVC.search(with: key)
        }
    }
    
    func viewControllerWillMove(newIndex: Int) {
        switch newIndex {
        case 0:
            communitiesVC.search(with: searchTextField.text)
        case 1:
            membersVC.search(with: searchTextField.text)
        case 2:
            hashtagVC.search(withText: searchTextField.text)
        case 3:
            postsVC.fetchPosts(keyword: searchTextField.text ?? "")
        default:
            break
        }
    }
}

extension AmitySearchViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setButtonBarHidden(hidden: false)
        textField.resignFirstResponder()
        debouncer.run {
            self.handleSearch(with: textField.text)
        }
        return true
    }
}

protocol AmitySearchViewControllerAction: AnyObject {
    func search(with text: String?)
}
