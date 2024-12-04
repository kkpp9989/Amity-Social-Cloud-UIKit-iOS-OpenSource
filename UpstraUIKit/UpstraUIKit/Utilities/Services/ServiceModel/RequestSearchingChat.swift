//
//  RequestSearchingChat.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct jsonChannelOptions {
    var limit: Int?
    var next: String?
}

enum orderByResponse: String {
    case desc = "desc"
    case asc = "asc"
}

struct RequestSearchingChat {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    let apiKey = AmityUIKitManagerInternal.shared.apiKey
    let userId = AmityUIKitManagerInternal.shared.currentUserId
    var keyword: String = ""
    var size: Int = 20
    var paginateToken: String = ""
    var isMemberOnly: Bool = false
    var orderBy: orderByResponse?
    
    func requestSearchMessages(_ completion: @escaping(Result<AmitySearchMessagesModel,Error>) -> ()) {
        let domainURL = "https://api.sg.amity.co/api/v1"
        var urlReuest = "\(domainURL)/search/messages?query=\(keyword)&options[limit]=\(size)"
        
        if !paginateToken.isEmpty {
            urlReuest += "&options[token]=\(paginateToken)"
        }
        requestMeta.urlRequest = urlReuest
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .get
        requestMeta.encoding = .urlEncoding
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(AmitySearchMessagesModel.self, from: data) else {
                    logErrorDeCodeData(data: data)
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func requestSearchChannels(types: [AmityChannelViewType], _ completion: @escaping(Result<SearchChannelsModel,Error>) -> ()) {
        let domainURL = "https://api.sg.amity.co"
        
        var channelType: String = ""
        for (index, type) in types.enumerated() {
            switch type {
            case .broadcast:
                channelType += "types[]=broadcast\(index < (types.count - 1) ? "&" : "")"
            case .group:
                channelType += "types[]=community\(index < (types.count - 1) ? "&" : "")"
            default:
                break
            }
        }
        
        var urlRequest = "\(domainURL)/api/v2/search/channels?query=\(keyword)&\(channelType)&options[limit]=\(size)&exactMatch=false&isMemberOnly=\(isMemberOnly)"

        if !paginateToken.isEmpty {
            urlRequest += "&options[token]=\(paginateToken)"
        }
        
        if let orderBy = orderBy {
            urlRequest += "&options[orderBy]=\(orderBy.rawValue)"
        }
        
        requestMeta.urlRequest = urlRequest
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .get
        requestMeta.encoding = .urlEncoding
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(SearchChannelsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                
                completion(.success(dataModel))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func logErrorDeCodeData(data: Data) {
        do {
            let _ = try JSONDecoder().decode(AmitySearchMessagesModel.self, from: data)
        } catch {
            print("Parsing Error : \(String(describing: error))")
        }
    }
}
