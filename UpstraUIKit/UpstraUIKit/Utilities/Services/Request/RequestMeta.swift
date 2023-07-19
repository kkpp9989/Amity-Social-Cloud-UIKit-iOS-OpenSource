//
//  RequestMeta.swift
//  Service
//
//  Created by PrInCeInFiNiTy on 28/6/2566 BE.
//

import Foundation

enum HTTPMethod: String {
    case connect = "CONNECT"
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    case trace = "TRACE"
}

enum EnCoding {
    case jsonEncoding
    case urlEncoding
}

protocol RequestMeta {
    var urlRequest: String { get }
    var header: [[String:Any]] { get set }
    var params: [String:Any?] { get set }
    var method: HTTPMethod { get set }
    var imageDataUpload:[AnyObject] { get set }
    var encoding: EnCoding { get set }
}

class BaseRequestMeta: RequestMeta {
    var urlRequest: String = ""
    var header: [[String:Any]] = []
    var params: [String:Any?] = [:]
    var method: HTTPMethod = .get
    var imageDataUpload: [AnyObject] = []
    var encoding: EnCoding = .jsonEncoding
}

