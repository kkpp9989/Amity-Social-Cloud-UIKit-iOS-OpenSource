//
//  AmityMentionManager.swift
//  AmityUIKit
//
//  Created by Hamlet on 08.11.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import AmitySDK
import UIKit

public struct AmityMentionUserModel {
    let userId: String
    let displayName: String
    let avatarURL: String
    let isGlobalBan: Bool
    
    init(user: AmityUser) {
        self.userId = user.userId
        self.displayName = user.displayName ?? AmityLocalizedStringSet.General.anonymous.localizedString
        self.avatarURL = user.getAvatarInfo()?.fileURL ?? ""
        self.isGlobalBan = user.isGlobalBanned
    }
}

public protocol AmityMentionManagerDelegate: AnyObject {
    func didGetUsers(users: [AmityMentionUserModel])
    func didCreateAttributedString(attributedString: NSAttributedString)
    func didMentionsReachToMaximumLimit()
    func didCharactersReachToMaximumLimit()
    func didGetHashtag(keywords: [AmityHashtagModel])
}

public enum AmityMentionManagerType {
    case post(communityId: String?)
    case comment(communityId: String?)
    case message(channelId: String?)
}

final public class AmityMentionManager {
    // Properties
    private let type: AmityMentionManagerType
    private var mentions: [AmityMention] = []
    private var searchingKey: String? = nil
    private(set) var isSearchingStarted: Bool = false
    private(set) var isSearchingHashtagStarted: Bool = false
    public var users: [AmityMentionUserModel] = []
    public var keywords: [AmityHashtagModel] = []
    private let communityId: String?
    private let channelId: String?
    private var font: UIFont = AmityFontSet.body
    private var highlightFont = AmityFontSet.bodyBold
    private var foregroundColor = AmityColorSet.base
    private var highlightColor = AmityColorSet.primary
    
    // Private community
    private lazy var privateCommunityRepository: AmityCommunityRepository = AmityCommunityRepository(client: AmityUIKitManagerInternal.shared.client)
    private var privateCommunityMembersCollection: AmityCollection<AmityCommunityMember>?
    private var communityObject: AmityObject<AmityCommunity>?
    private var token: AmityNotificationToken?
    private var community: AmityCommunityModel?
    private var channel: AmityChannelModel?
    
    // Chat channel
    private var channelMembership: AmityChannelMembership?
    private var channelCollectionToken: AmityNotificationToken?
    private var channelNotificationToken: AmityNotificationToken?
    private let channelRepository: AmityChannelRepository = AmityChannelRepository(client: AmityUIKitManagerInternal.shared.client)
    
    // User repository
    private lazy var userRepository: AmityUserRepository = AmityUserRepository(client: AmityUIKitManagerInternal.shared.client)
    private var usersCollection: AmityCollection<AmityUser>?
    
    private var collectionToken: AmityNotificationToken?
    
    public static let maximumCharacterCountForPost = 20000 // [Custom for ONE Krungthai] Change value from 50,000 to 20,000 refer to requirement
    public static let maximumMentionsCount = 30
    
    public weak var delegate: AmityMentionManagerDelegate?
    
    public init(withType type: AmityMentionManagerType) {
        self.type = type
        switch type {
        case .post(let communityId), .comment(let communityId):
            self.communityId = communityId
            self.channelId = nil
            if let communityId = communityId {
                communityObject = privateCommunityRepository.getCommunity(withId: communityId)
                token = communityObject?.observe { [weak self] community, error in
                    if community.dataStatus == .fresh {
                        self?.token?.invalidate()
                    }
                    guard let object = community.snapshot else { return }
                    
                    self?.community = AmityCommunityModel(object: object)
                }
            }
        case .message(channelId: let channelId):
            self.communityId = nil
            self.channelId = channelId
            if let channelId = channelId {
                channelNotificationToken = channelRepository.getChannel(channelId).observe { [weak self] (channel, error) in
                    if channel.dataStatus == .fresh {
                        self?.channelNotificationToken?.invalidate()
                    }
                    guard let object = channel.snapshot else { return }
                    self?.channel = AmityChannelModel(object: object)
                }
            }
        }
    }
}

// MARK: - Public methods
public extension AmityMentionManager {
    func shouldChangeTextIn(_ textInput: UITextInput, inRange range: NSRange, replacementText: String, currentText text: String) -> Bool {
        if replacementText == "@" {
            for i in 0..<mentions.count {
                if range.location < mentions[i].index {
                    mentions[i].index += replacementText.count
                }
            }
            
            if text == "" {
                isSearchingStarted = true
                search(withText: "")
                return true
            } else {
                if let selectedRange = textInput.selectedTextRange, canHanldeMention(textInput, inRange: range, withSelectedRange: selectedRange, inText: text) {
                    return true
                }
                finishSearching()
                return true
            }
        } else if replacementText == "#" {
            if text == "" {
                isSearchingHashtagStarted = true
                searchHashtag(withText: "")
                return true
            } else {
                if let selectedRange = textInput.selectedTextRange, canHanldeHashtag(textInput, inRange: range, withSelectedRange: selectedRange, inText: text) {
                    return true
                }
                finishHashtagSearching()
                return true
            }
        } else if replacementText == "" { // Started to remove
            // Removing during search
            if isSearchingStarted {
                if (searchingKey?.count ?? 0) > 0 {
                    searchingKey?.removeLast()
                    search(withText: searchingKey ?? "")
                } else if text.count > 0, text.dropLast().hasSuffix("@") {
                    searchingKey = ""
                    isSearchingStarted = true
                    search(withText: searchingKey ?? "")
                } else {
                    finishSearching()
                }
                return true
            }
            
            if isSearchingHashtagStarted {
                if (searchingKey?.count ?? 0) > 0 {
                    searchingKey?.removeLast()
                    searchHashtag(withText: searchingKey ?? "")
                } else if text.count > 0, text.dropLast().hasSuffix("#") {
                    searchingKey = ""
                    isSearchingStarted = true
                    searchHashtag(withText: searchingKey ?? "")
                } else {
                    finishHashtagSearching()
                }
                return true
            }
            
            // Removing something from the text
            if let startPosition = textInput.position(from: textInput.beginningOfDocument, offset: range.location),
               let endPosition = textInput.position(from: textInput.beginningOfDocument, offset: range.location + range.length), let selectedRange = textInput.selectedTextRange {
                
                return canRemove(textInput, inRange: range, withSelectedRange: selectedRange, startPosition: startPosition, endPosition: endPosition, inText: text)
            }
        } else if isSearchingStarted {
            // when searching is started just append the replacement text to the searching key and make search
            if searchingKey == nil {
                searchingKey = ""
            }
            searchingKey?.append(replacementText)
            search(withText: searchingKey ?? "")
        } else if isSearchingHashtagStarted {
            // when searching is started just append the replacement text to the searching key and make search
            if searchingKey == nil {
                searchingKey = ""
            }
            searchingKey?.append(replacementText)
            searchHashtag(withText: searchingKey ?? "")
        } else { // when writing a text
            let finalText = text.appending(replacementText)
            if finalText.count > AmityMentionManager.maximumCharacterCountForPost {
                delegate?.didCharactersReachToMaximumLimit()
                return false
            }
            // if there is a mention after the current position then change the indexes of existing message
            for i in 0..<mentions.count {
                if range.location < mentions[i].index {
                    mentions[i].index += replacementText.count
                }
            }
            finishSearching()
            finishHashtagSearching()
        }
        
        return true
    }
    
    func changeSelection(_ textInput: UITextInput) {
        if isSearchingStarted || isSearchingHashtagStarted { return }

        guard let selectedRange = textInput.selectedTextRange, selectedRange != textInput.textRange(from: textInput.endOfDocument, to: textInput.endOfDocument), selectedRange != textInput.textRange(from: textInput.beginningOfDocument, to: textInput.beginningOfDocument) else { return }
        
        let cursorPosition = textInput.offset(from: textInput.beginningOfDocument, to: selectedRange.start)
        
        for mention in mentions {
            if mention.index <= cursorPosition && mention.index + mention.length >= cursorPosition,
			   let startPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention.index),
			   let endPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention.index + mention.length + 1)  {
                if selectedRange == textInput.textRange(from:startPosition, to: endPosition) { return }
                textInput.selectedTextRange = textInput.textRange(from:startPosition, to: endPosition)
            }
        }
    }
    
    func addMention(from textInput: UITextInput, in text: String, at indexPath: IndexPath) {
        if mentions.count == AmityMentionManager.maximumMentionsCount {
            delegate?.didMentionsReachToMaximumLimit()
            return
        }
        
        guard let selectedRange = textInput.selectedTextRange, indexPath.row < users.count else { return }
        
        var currentText = text
        let member = users[indexPath.row]
        
        if member.isGlobalBan {
            return
        }
        
        let userId: String? = member.userId
        let displayName: String = member.displayName
        let type: AmityMessageMentionType = .user
        
        // adding a mention from ending
        var range = NSRange()
        
        let key = searchingKey ?? ""
        let rng = Range(NSRange(location: currentText.utf16.count - key.utf16.count, length: key.utf16.count), in: currentText)
        
        let start = (currentText.utf16.count - (searchingKey?.utf16.count ?? 0)) - 1
        range = NSRange(location: start == 1 ? 0 : start , length: displayName.utf16.count + 1)
        currentText = currentText.replacingOccurrences(of: "\(searchingKey ?? "")", with: "",range: rng)
        currentText.append("\(displayName) ")
        
        let mention = AmityMention(type: type, index: range.location, length: range.length, userId: userId)
        
        mentions.append(mention)
        
        createAttributedText(text: currentText)
        finishSearching()
    }
    
    func addHashtag(from textInput: UITextInput, in text: String, at indexPath: IndexPath) {
        guard let selectedRange = textInput.selectedTextRange, indexPath.row < keywords[indexPath.row].text?.count ?? 0 else { return }
        
        var currentText = text
        let keyword = keywords[indexPath.row]
                
        // adding a hashtag from ending
        let key = searchingKey ?? ""
        let rng = Range(NSRange(location: currentText.utf16.count - key.utf16.count, length: key.utf16.count), in: currentText)
        currentText = currentText.replacingOccurrences(of: "\(searchingKey ?? "")", with: "",range: rng)
        currentText.append("\(keyword.text ?? "") ")
        
        createAttributedText(text: currentText)
        finishHashtagSearching()
    }
    
    func item(at indexPath: IndexPath) -> AmityMentionUserModel? {
        guard indexPath.row < users.count else { return nil }
        return users[indexPath.row]
    }
    
    func itemHashtag(at indexPath: IndexPath) -> AmityHashtagModel? {
        guard indexPath.row < keywords.count else { return nil }
        return keywords[indexPath.row]
    }
    
    func loadMore() {
        if communityId == nil || (community?.isPublic ?? false) {
            if usersCollection?.hasNext ?? false {
                usersCollection?.nextPage()
            }
            return
        }
        
        if privateCommunityMembersCollection?.hasNext ?? false {
            privateCommunityMembersCollection?.nextPage()
        }
    }
    
    func loadMoreHashtag() {
    }
    
    func setMentions(metadata: [String: Any], inText text: String) {
        mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        createAttributedText(text: text)
    }
    
    func setHashtag(inText text: String) {
        createAttributedText(text: text)
    }
    
    func getMetadata(shift: Int = 0) -> [String: Any]? {
        if mentions.isEmpty { return nil }
        
        let finalMentions = mentions
        
        if shift != 0 {
            for i in 0..<finalMentions.count {
                finalMentions[i].index += shift
            }
        }
        
        return AmityMentionMapper.metadata(from: finalMentions)
    }
    
    func getMentionees() -> AmityMentioneesBuilder? {
        if mentions.isEmpty { return nil }
        
        let mentionees: AmityMentioneesBuilder = AmityMentioneesBuilder()
        
        let userIds = mentions.filter{ $0.type == .user }.compactMap { $0.userId }
        if !userIds.isEmpty {
            mentionees.mentionUsers(userIds: userIds)
        }
        
        return mentionees
    }
    
    func setColor(_ foregroundColor: UIColor, highlightColor: UIColor) {
        self.foregroundColor = foregroundColor
        self.highlightColor = highlightColor
    }
    
    func setFont(_ font: UIFont, highlightFont: UIFont) {
        self.font = font
        self.highlightFont = highlightFont
    }
    
    func resetState() {
        mentions = []
        searchingKey = nil
        isSearchingStarted = false
        isSearchingHashtagStarted = false
        users = []
        keywords = []
        collectionToken?.invalidate()
        collectionToken = nil
        privateCommunityMembersCollection = nil
        usersCollection = nil
    }
}

// MARK: - Private methods
private extension AmityMentionManager {
    func search(withText text: String) {
        if channelId == nil {
            if communityId == nil || (community?.isPublic ?? false) {
                usersCollection = userRepository.searchUser(text, sortBy: .displayName)
                collectionToken = usersCollection?.observe { [weak self] (collection, _, error) in
                    self?.handleSearchResponse(with: collection)
                }
                return
            }
        }
                
        if let communityId = communityId {
            privateCommunityMembersCollection = privateCommunityRepository.searchMembers(communityId: communityId, displayName: text, membership: [.member], roles: [], sortBy: .lastCreated)
            collectionToken = privateCommunityMembersCollection?.observe { [ weak self] (collection, change, error) in
                self?.handleSearchResponse(with: collection)
            }
        }
        
        if let _ = channelId {
            if !(channel?.isConversationChannel ?? false) {
                let builder = AmityChannelMembershipFilterBuilder()
                builder.add(filter: .member)
                channelCollectionToken = channel?.participation.searchMembers(displayName: "", filterBuilder: builder, roles: []).observe({ [weak self] collection, _, _  in
                    self?.handleSearchResponse(with: collection)
                })
            }
        }
    }
    
    func searchHashtag(withText text: String) {
        var serviceRequest = RequestHashtag()
        serviceRequest.keyword = text
        serviceRequest.request { result in
            switch result {
            case .success(let dataResponse):
                self.keywords = dataResponse.hashtag ?? []
                self.handleSearchHashtagResponse()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func handleSearchHashtagResponse() {
        DispatchQueue.main.async { [self] in
            if isSearchingHashtagStarted {
                delegate?.didGetHashtag(keywords: keywords)
            }
        }
    }
    
    func handleSearchResponse<T>(with collection: AmityCollection<T>) {
        switch collection.dataStatus {
        case .fresh:
            users = []
            for index in 0..<collection.count() {
                guard let object = collection.object(at: index) else { continue }
                if T.self == AmityCommunityMember.self {
                    guard let memberObject = object as? AmityCommunityMember, let user = memberObject.user else { continue }
                    users.append(AmityMentionUserModel(user: user))
                } else if T.self == AmityChannelMember.self {
                    guard let memberObject = object as? AmityChannelMember, let user = memberObject.user else { continue }
                    users.append(AmityMentionUserModel(user: user))

                } else {
                    guard let userObject = object as? AmityUser else { continue }
                    users.append(AmityMentionUserModel(user: userObject))
                }
            }
            if isSearchingStarted {
                delegate?.didGetUsers(users: users)
            }
        case .error:
            collectionToken?.invalidate()
            delegate?.didGetUsers(users: users)
        default: break
        }
    }
    
    func finishSearching() {
        users = []
        searchingKey = nil
        isSearchingStarted = false
        
        delegate?.didGetUsers(users: users)
    }
    
    func finishHashtagSearching() {
        keywords = []
        searchingKey = nil
        isSearchingHashtagStarted = false
        
        delegate?.didGetHashtag(keywords: keywords)
    }
    
    func removeMention(at range: NSRange) {
        // Find the mention and remove
        let theMentionToRemove = mentions.filter { mention in
            mention.index <= range.location && mention.index + mention.length >= range.location
        }
        
        if theMentionToRemove.count > 0 {
            let mentionToRemove = theMentionToRemove[0]
            mentions.removeAll { mention in
                mention.index == mentionToRemove.index
            }
            
            for i in 0..<mentions.count {
                if mentions[i].index > mentionToRemove.index {
                    // There is a space after every mention, range.length + 1 to count total length included the space
                    mentions[i].index = mentions[i].index - (range.length + 1)
                }
            }
        }
    }
    
    func hasMentionInRange(range: NSRange) -> Bool {
        let filteredMenion = mentions.filter { mention in
            mention.index <= range.location && mention.index + mention.length >= range.location
        }

        return filteredMenion.count > 0
    }
    
    public func createAttributedText(text: String) {
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([.font: font, .foregroundColor: foregroundColor], range: NSMakeRange(0, text.utf16.count))
        
        // Add attributes for mentions
        mentions.forEach { mention in
            attributedString.addAttributes([.foregroundColor: highlightColor, .font: highlightFont], range: NSMakeRange(mention.index, mention.length))
        }
        
        // Add attributes for hashtags
        let hashtagRegex = try? NSRegularExpression(pattern: "#\\w+", options: [])
        if let matches = hashtagRegex?.matches(in: text, options: [], range: NSMakeRange(0, text.utf16.count)) {
            for match in matches {
                attributedString.addAttributes([.foregroundColor: highlightColor, .font: highlightFont], range: match.range)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            delegate?.didCreateAttributedString(attributedString: attributedString)
        }
        
        if text.count > AmityMentionManager.maximumCharacterCountForPost {
            delegate?.didCharactersReachToMaximumLimit()
        }
    }
    
    // This method handles the activation of mention feature when text is not empty.
    // If can handle then will configure searchingKey and will call searc function
    func canHanldeMention(_ textInput: UITextInput, inRange range: NSRange, withSelectedRange selectedRange: UITextRange, inText text: String) -> Bool {
        let startPosition: UITextPosition = textInput.beginningOfDocument
        let endPosition: UITextPosition = textInput.endOfDocument
        
        // There are 3 cases for cursor position:
        //  - in the begining: can activate and make search if there is a space on the right side of the cursor
        //  - in the middle: can activate and make search if there are only space on the both right and left sides of the cursor
        //  - in the end: can activate and make search if there is a space on the left side of the cursor
        
        if let currentRange = textInput.textRange(from: endPosition, to: endPosition), selectedRange == currentRange, let leftRange = Range(NSRange(location: range.location  > 0 ? range.location - 1 : 0, length: range.length), in: text) {
            // In the end
            let leftSubstring = String(text[leftRange.lowerBound])
            let leftTrimmedString = leftSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
            if leftTrimmedString.isEmpty {
                isSearchingStarted = true
                search(withText: searchingKey ?? "")
                return true
            }
        } else if let currentRange = textInput.textRange(from: startPosition, to: startPosition), selectedRange == currentRange, let rightRange = Range(NSRange(location: range.location  > 0 ? range.location + 1 : 0, length: range.length), in: text) {
            // in the beginning
            let rightSubstring = String(text[rightRange.lowerBound])
            let rightTrimmedString = rightSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
            if rightTrimmedString.isEmpty {
                isSearchingStarted = true
                search(withText: searchingKey ?? "")
                return true
            }
        } else if let leftRange = Range(NSRange(location: range.location  > 0 ? range.location - 1 : 0, length: range.length), in: text), let rightRange = Range(NSRange(location: range.location, length: range.length), in: text) {
            // in the middle
            
            let leftSubstring = String(text[leftRange.lowerBound])
            let leftTrimmedString = leftSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
                
            let rightSubstring = String(text[rightRange.lowerBound])
            let rightTrimmedString = rightSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
                
            if rightTrimmedString.isEmpty && leftTrimmedString.isEmpty {
                isSearchingStarted = true
                search(withText: searchingKey ?? "")
                return true
            }
        }
        return false
    }
    
    func canHanldeHashtag(_ textInput: UITextInput, inRange range: NSRange, withSelectedRange selectedRange: UITextRange, inText text: String) -> Bool {
        let startPosition: UITextPosition = textInput.beginningOfDocument
        let endPosition: UITextPosition = textInput.endOfDocument
        
        // There are 3 cases for cursor position:
        //  - in the begining: can activate and make search if there is a space on the right side of the cursor
        //  - in the middle: can activate and make search if there are only space on the both right and left sides of the cursor
        //  - in the end: can activate and make search if there is a space on the left side of the cursor
        
        if let currentRange = textInput.textRange(from: endPosition, to: endPosition), selectedRange == currentRange, let leftRange = Range(NSRange(location: range.location  > 0 ? range.location - 1 : 0, length: range.length), in: text) {
            // In the end
            let leftSubstring = String(text[leftRange.lowerBound])
            let leftTrimmedString = leftSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
            if leftTrimmedString.isEmpty {
                isSearchingHashtagStarted = true
                searchHashtag(withText: searchingKey ?? "")
                return true
            }
        } else if let currentRange = textInput.textRange(from: startPosition, to: startPosition), selectedRange == currentRange, let rightRange = Range(NSRange(location: range.location  > 0 ? range.location + 1 : 0, length: range.length), in: text) {
            // in the beginning
            let rightSubstring = String(text[rightRange.lowerBound])
            let rightTrimmedString = rightSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
            if rightTrimmedString.isEmpty {
                isSearchingHashtagStarted = true
                searchHashtag(withText: searchingKey ?? "")
                return true
            }
        } else if let leftRange = Range(NSRange(location: range.location  > 0 ? range.location - 1 : 0, length: range.length), in: text), let rightRange = Range(NSRange(location: range.location, length: range.length), in: text) {
            // in the middle
            let leftSubstring = String(text[leftRange.lowerBound])
            let leftTrimmedString = leftSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
                
            let rightSubstring = String(text[rightRange.lowerBound])
            let rightTrimmedString = rightSubstring.trimmingCharacters(in: .whitespacesAndNewlines)
                
            if rightTrimmedString.isEmpty && leftTrimmedString.isEmpty {
                isSearchingHashtagStarted = true
                searchHashtag(withText: searchingKey ?? "")
                return true
            }
        }
        return false
    }
    
    // Checks is it possible to remove the text in the selected range
    // If it's possible then removes the selected mention in the given range if there is any
    func canRemove(_ textInput: UITextInput, inRange range: NSRange, withSelectedRange selectedRange: UITextRange, startPosition: UITextPosition, endPosition: UITextPosition, inText text: String) -> Bool {
        // Removing the selected text
        if selectedRange == textInput.textRange(from:startPosition, to: endPosition) {
            // check is there a mention in selected range, if there is any then remove
            if hasMentionInRange(range: range) {
                removeMention(at: range)
            } else {
                configureMentions(inRange: range, forText: text)
            }
        } else {
            // Check wheater removing the mention of the ending
            let mention = mentions.filter { model in
                let rangeAfterChange = range.location - 1
                return rangeAfterChange >= model.index && rangeAfterChange <= model.index + model.length
            }
            
            if mention.count > 0 {
                // Select the whole mention
                if let startPosition = textInput.position(from: textInput.beginningOfDocument, in: .right, offset: mention[0].index),
                   let endPosition = textInput.position(from: textInput.beginningOfDocument, in: .right, offset: mention[0].index + mention[0].length + 1) {
                    textInput.selectedTextRange = textInput.textRange(from: startPosition, to: endPosition)
                    return false
                }
                
                if let selectedRange = textInput.selectedTextRange,
                   selectedRange == textInput.textRange(from: textInput.endOfDocument, to: textInput.endOfDocument) {
                    let cursorPosition = textInput.offset(from: textInput.beginningOfDocument, to: selectedRange.start)
                    if mention[0].index <= cursorPosition && mention[0].index + mention[0].length >= cursorPosition,
                       let startPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention[0].index),
                       let endPosition = textInput.position(from: textInput.beginningOfDocument, offset: mention[0].index + mention[0].length)  {
                                
                        if selectedRange == textInput.textRange(from:startPosition, to: endPosition) { return false }
                        textInput.selectedTextRange = textInput.textRange(from:startPosition, to: endPosition)
                        removeMention(at: range)
                    }
                }
            } else {
                configureMentions(inRange: range, forText: text)
                
                finishSearching()
            }
        }
        return true
    }
    
    // Configures the indexes of remaining mentions after removing a mention or text in the given range
    func configureMentions(inRange range: NSRange, forText text: String) {
        guard range.length > 0 else { return }
        // If there is no mention in the selected range then change the indexes of every mention from mentions array
        var space = 0
        
        if (range.location > 0) && range.location + range.length < text.count {
            let charBefore = text[text.index(text.startIndex, offsetBy: range.location - 1)]
            let charAfter = text[text.index(text.startIndex, offsetBy: range.location + range.length)]
            
            if charBefore == " " && charBefore == charAfter {
                space = 1
            }
        }
        
        for i in 0..<mentions.count {
            if range.location < mentions[i].index {
                let newIndex = mentions[i].index - (range.length == 0 ? 1 : (range.length + space))
                mentions[i].index = newIndex > 0 ? newIndex : 0
            }
        }
    }
}

extension AmityMentionManager {
    static func getAttributes(fromText text: String, withMetadata metadata: [String: Any], mentionees: [AmityMentionees], shift: Int = 0, highlightColor: UIColor = AmityColorSet.primary, highlightFont: UIFont = AmityFontSet.bodyBold) -> [MentionAttribute] {
        var attributes = [MentionAttribute]()
        
        let mentions = AmityMentionMapper.mentions(fromMetadata: metadata)
        if mentions.isEmpty || mentionees.isEmpty { return [] }
        
        var users: [AmityUser] = []
        let mentionee = mentionees[0]
        if mentionee.type == .user, let usersArray = mentionee.users {
            users = usersArray
        }
        
        for mention in mentions {
            if mention.index < 0 || mention.length <= 0 { continue }
            
            var shouldMention = true
            
            if mention.type == .user {
                shouldMention = users.contains(where: { user in
                    user.userId == mention.userId
                })
            }
            
            let range = NSRange(location: mention.index, length: mention.length)
            attributes.append(MentionAttribute(attributes: [.foregroundColor: highlightColor, .font: highlightFont], range: range, userId: mention.userId ?? ""))
        }

        return attributes
    }
}
