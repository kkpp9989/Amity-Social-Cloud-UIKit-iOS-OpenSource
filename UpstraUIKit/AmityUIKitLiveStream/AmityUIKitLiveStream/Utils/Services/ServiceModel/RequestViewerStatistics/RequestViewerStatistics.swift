//
//  RequestViewerStatistics.swift
//  AmityUIKitLiveStream
//
//  Created by Thanaphat Thanawatpanya on 20/7/2566 BE.
//

import Foundation
import AmityUIKit

struct RequestViewerStatistics {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    // [Deprecated]
    func sendViewerStatistics(postId: String, viewerUserId: String, viewerDisplayName: String, isTrack: Bool, streamId: String, _ completion: @escaping(Result<ViewerStatisticsModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/viewerCount"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "userId": viewerUserId, "displayName": viewerDisplayName, "isTrack": isTrack, "streamId": streamId]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewerStatisticsModel.self, from: data) else {
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
    
    // [Current use][Custom for ONE Krungthai] Request get viewer count from custom API
    func getViewerCount(postId: String, _ completion: @escaping(Result<ViewersModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }

        requestMeta.method = .get
        requestMeta.urlRequest = "\(domainURL)/viewerCountRedis?postId=\(postId)"
        requestMeta.encoding = .urlEncoding
        requestMeta.header = [
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewerStatisticsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel.data!))
                
                let responseDataString = String(data: data, encoding: .utf8)
                print("[Livestream][getViewerCount] Response Data: \(responseDataString ?? "Unable to convert data to string")")
                
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request connect livestream to backend by custom API
    func connectLivestream(postId: String, viewerUserId: String, viewerDisplayName: String, streamId: String, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/connect"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "userId": viewerUserId, "displayName": viewerDisplayName, "streamId": streamId]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                // [Current] Use boolean instead because reponse is text only and not use in UI
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request disconnect livestream to backend by custom API
    func disconnectLivestream(postId: String, viewerUserId: String, viewerDisplayName: String, streamId: String, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .delete
        requestMeta.urlRequest = "\(domainURL)/connect"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "userId": viewerUserId, "displayName": viewerDisplayName, "streamId": streamId]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                // [Current] Use boolean instead because reponse is text only and not use in UI
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    // [Current use][Custom for ONE Krungthai] Request create livestream log to backend by custom API
    func createLiveStreamLog(postId: String, viewerUserId: String, viewerDisplayName: String, streamId: String, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/createLivestream"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "userId": viewerUserId, "displayName": viewerDisplayName, "streamId": streamId]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewerStatisticsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func liveStreamStatus(postId: String, streamId: String, isLive: Bool, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/live-status"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "streamId": streamId, "isLive": isLive]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewerStatisticsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func getLiveStreamStatus(postId: String, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .get
        requestMeta.urlRequest = "\(domainURL)/live-status?postId=\(postId)"
        requestMeta.encoding = .urlEncoding
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
                      let jsonDict = json as? [String: Any],
                      let isLiveResponse = jsonDict["isLive"] as? Bool else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(isLiveResponse))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }

}
