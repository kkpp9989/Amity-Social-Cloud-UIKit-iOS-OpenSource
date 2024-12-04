//
//  RequestGetNotification.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 21/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestGetNotification {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    
    func requestNotificationHistory(_ timeStamp: Int, _ completion: @escaping(Result<AmityNotificationTrayModel,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        var endpointURL = "/notifications/v3/history"
        if timeStamp != 0 {
            endpointURL += "?startAfter=\(timeStamp)"
        }
        requestMeta.urlRequest = "\(domainURL)\(endpointURL)"
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
            
            // Print the JSON response
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("-------> JSON Response: \(jsonString)")
            }

            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(AmityNotificationTrayModel.self, from: data) else {
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
    
    func requestNotificationTotalUnreadCount(_ completion: @escaping(Result<AmityNotificationUnreadCount,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/notifications/v3"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .get
        requestMeta.encoding = .withQueryParameters(queryParameters: [:])
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(AmityNotificationUnreadCount.self, from: data) else {
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
    
    func requestNotificationLastRead(_ completion: @escaping(Result<Bool,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/notifications/v2/last-read"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(Bool.self, from: data) else {
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
    
    func requestNotificationRead(_ postType: String, targetId: String, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/notifications/v2/read"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.params = ["verb": postType, "targetId": targetId]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("-------> JSON Response: \(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func logErrorDeCodeData(data: Data) {
        do {
            let _ = try JSONDecoder().decode(Bool.self, from: data)
        } catch {
            print("Parsing Error : \(String(describing: error))")
        }
    }
}
