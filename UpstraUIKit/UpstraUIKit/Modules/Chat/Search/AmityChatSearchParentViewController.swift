//
//  AmityChatSearchParentViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public class AmityChatSearchParentViewController: AmityPageViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var searchTextField: UITextField!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var searchView: UIView!
    @IBOutlet private weak var searchStackView: UIStackView!
    @IBOutlet private weak var searchIcon: UIImageView!
    
    // MARK: - Child ViewController
    private var messageVC = AmityMessagesSearchViewController.make(title: AmityLocalizedStringSet.messages.localizedString)
    private var membersVC = AmityMemberSearchViewController.make(title: AmityLocalizedStringSet.accounts.localizedString)
    private var groupVC = AmityChannelsSearchViewController.make(title: AmityLocalizedStringSet.groups.localizedString)

    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    private let debouncer = Debouncer(delay: 0.5)

    private init() {
        super.init(nibName: AmityChatSearchParentViewController.identifier, bundle: AmityUIKitManager.bundle)
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
        
        // Update result in current tab if need
        updateResultCurrentTabIfneed()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public static func make() -> AmityChatSearchParentViewController {
        return AmityChatSearchParentViewController()
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        return [messageVC, membersVC, groupVC]
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
            self.setButtonBarHidden(hidden: false)
            self.handleSearch(with: sender.text)
        }
    }
}

private extension AmityChatSearchParentViewController {
    func handleSearch(with key: String?) {
        print(#"[Search][Channel] Handle search with keyword \#(key) of currentIndex: \#(currentIndex)"#)
        if viewControllers[currentIndex] == messageVC {
            messageVC.search(withText: key)
        } else if viewControllers[currentIndex] == groupVC {
            groupVC.search(withText: key)
        } else {
            membersVC.search(with: key)
        }
    }
    
    func viewControllerWillMove(newIndex: Int) {
        switch newIndex {
        case 0:
            print("[Search][Channel] Go to tab Messages with newIndex: \(newIndex)")
            messageVC.search(withText: searchTextField.text)
        case 1:
            print("[Search][Channel] Go to tab Accounts with newIndex: \(newIndex)")
            membersVC.search(with: searchTextField.text)
        case 2:
            print("[Search][Channel] Go to tab Groups with newIndex: \(newIndex)")
            groupVC.search(withText: searchTextField.text)
        default:
            break
        }
    }
    
    func updateResultCurrentTabIfneed() {
        switch currentIndex {
        case 2: // Index 2 : Group | Update result in search group because it got data from API one time and may be user joined chat in chat detail after searching
            print("[Search][Channel] Update result search in Groups with currentIndex: \(currentIndex)")
            groupVC.search(withText: searchTextField.text)
        default:
            break
        }
    }
}

extension AmityChatSearchParentViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setButtonBarHidden(hidden: false)
        textField.resignFirstResponder()
        return true
    }
}

protocol AmityChatSearchParentViewControllerAction: AnyObject {
    func search(with text: String?)
}
