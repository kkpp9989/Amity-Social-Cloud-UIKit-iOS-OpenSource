//
//  NetworkManager.swift
//  Service
//
//  Created by PrInCeInFiNiTy on 28/6/2566 BE.
//

import UIKit
import Foundation

class NetworkManager {
    
    let timeoutIntervalForRequest: Double = 60.0
    let timeoutIntervalForResource: Double = 60.0
    
    public func request(_ requestMeta:BaseRequestMeta, completion: @escaping(Data?, URLResponse?, Error?) -> ()) {
        var httpRequest: URLRequest
        var session: URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        configuration.timeoutIntervalForResource = timeoutIntervalForResource
        session = URLSession(configuration: configuration)
        switch requestMeta.encoding {
        case .jsonEncoding:
            httpRequest = URLRequest(url: URL(string: requestMeta.urlRequest.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!)
            httpRequest.httpMethod = requestMeta.method.rawValue
            httpRequest.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
            for value in requestMeta.header {
                for dicDataValue in value.enumerated() {
                    httpRequest.setValue(dicDataValue.element.value as? String, forHTTPHeaderField: dicDataValue.element.key)
                }
            }
            let jsonData = try? JSONSerialization.data(withJSONObject: requestMeta.params)
            httpRequest.httpBody = jsonData
        case .urlEncoding:
            httpRequest = URLRequest(url: URL(string: requestMeta.urlRequest.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")!)
            httpRequest.httpMethod = requestMeta.method.rawValue
            httpRequest.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
            for value in requestMeta.header {
                for dicDataValue in value.enumerated() {
                    httpRequest.setValue(dicDataValue.element.value as? String, forHTTPHeaderField: dicDataValue.element.key)
                }
            }
        }
        let task = session.dataTask(with: httpRequest) { (data, response, error) in
            completion(data, response, error)
        }
        task.resume()
    }
    
}
