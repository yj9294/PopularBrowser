//
//  BaseRequest.swift
//  BPDeliverer
//
//  Created by yangjian on 2023/12/18.
//

import Foundation
import Alamofire
import AdSupport
import UIKit
import CoreTelephony


let sessionManager: Session = {
    let configuration = URLSessionConfiguration.af.default
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    return Session(configuration: configuration)
}()


enum RequestCode : Int {
    case success = 200 //请求成功
    case networkFail = -9999 //网络错误
    case tokenMiss = 401 // token过期
    case tokenExpired = 403 // token过期
    case serverError = 500 // 服务器错误
    case jsonError = 501 // 解析错误
    case unknown = -8888 //未定义
}

/// 请求成功
typealias NetWorkSuccess = (_ obj:Any?) -> Void
/// 网络错误回调
typealias NetWorkError = (_ obj:Any?, _ code:RequestCode) -> Void
/// 主要用于网络请求完成过后停止列表刷新/加载
typealias NetWorkEnd = () -> Void

class Request {

    var method : HTTPMethod = .get
    var timeOut : TimeInterval = 65
    var decoding: Bool = true
    var eventType: String = RequestEventType.install.rawValue
    
    private var parameters : [String:Any]? = nil
    private var success : NetWorkSuccess?
    private var error : NetWorkError?
    private var end : NetWorkEnd?
    private var config : ((_ req:Request) -> Void)?
    private var query: [String: String]?
    private var id: String

    required init(id: String = UUID().uuidString,query: [String: String]? = nil, parameters: [String:Any]? = nil) {
        self.id = id
        self.parameters = parameters
        self.query = query
    }
    
    func netWorkConfig(config:((_ req:Request) -> Void)) -> Self {
        config(self)
        return self
    }
    
    @discardableResult
    func startRequestSuccess(success: NetWorkSuccess?) -> Self {
        self.success = success
        self.startRequest()
        return self
    }
    
    
    @discardableResult
    func end(end:@escaping NetWorkEnd) -> Self {
        self.end = end
        return self
    }

    @discardableResult
    func error(error:@escaping NetWorkError) -> Self {
        self.error = error
        return self
    }
    
    deinit {
        debugPrint("[API] request===============deinit")
    }
    
}

// MARK: 请求实现
extension Request {
    private func startRequest() -> Void {
        
        let startDate = Int(Date().timeIntervalSince1970 * 1000)
        
        var url: String = AppUtil.isDebug ? "https://test-incense.fastpopularsearch.com/pitiful/sultan/corvus" : "https://incense.fastpopularsearch.com/robot/askew/terrace"
    
        var queryDic: [String: String] =  self.query ?? [:]
        queryDic["english"] = "yarn"
        queryDic["hartman"] = "\(startDate)"
        queryDic["backstop"] = Locale.current.identifier
        queryDic["proctor"] = Bundle.main.bundleIdentifier
        queryDic["damocles"] = UIDevice.current.systemName + UIDevice.current.systemVersion
        query?.forEach({ key, value in
            queryDic[key] = value
        })
        
        if queryDic.count != 0  {
            if let cache = CacheUtil.shared.cache(id) {
                url = url + "?" + cache.query
            } else {
                let strings = queryDic.compactMap({ "\($0.key)=\($0.value)" })
                let string = strings.joined(separator: "&")
                url = url + "?" + string
            }
        }
        
        
        var headerDic:[String: String] = [:]
        if let cache = CacheUtil.shared.cache(id) {
            headerDic = cache.header
        } else {
            headerDic["damocles"] = UIDevice.current.systemName + UIDevice.current.systemVersion
        }
        
        var parameters: [String: Any] = [:]
        // 公共参数
        // 全局属性
        var can: [String: String] = [:]
        can["pobr_borth"] = Locale.current.languageCode
        parameters["immoral"] = can
        // ios = "yarn"
        parameters["english"] = "yarn"
        parameters["patient"] = CacheUtil.shared.getUUID()
        parameters["risky"] = UIDevice.current.identifierForVendor?.uuidString
        parameters["damocles"] = UIDevice.current.systemName + UIDevice.current.systemVersion
        parameters["myel"] = "apple"
        parameters["donna"] = UIDevice.current.systemVersion
        parameters["limitate"] = TimeZone.current.secondsFromGMT() / 3600
        parameters["proctor"] = Bundle.main.bundleIdentifier
        parameters["lop"] = UUID().uuidString
        parameters["backstop"] = Locale.current.identifier
        parameters["brought"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        parameters["hartman"] = startDate
        parameters["mira"] = ""
        parameters["harvest"] = CacheUtil.shared.getUUID()
        parameters["md"] = UUID().uuidString
        if #available(iOS 16, *) {
            parameters["ground"] = Locale.current.language.languageCode?.identifier
        } else {
            // Fallback on earlier versions
            parameters["ground"] = Locale.current.languageCode
        }
        
        if let cache = CacheUtil.shared.cache(id) {
            parameters = cache.parameter.json ?? [:]
        } else {
            self.parameters?.forEach({ (key, value) in
                parameters[key] = value
            })
        }
        
        
        var dataRequest : DataRequest!
        typealias RequestModifier = (inout URLRequest) throws -> Void
        let requestModifier : RequestModifier = { (rq) in
            rq.timeoutInterval = self.timeOut
            if self.method != .get {
                rq.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                rq.httpBody = parameters.data
            }
            debugPrint("[API] -----------------------")
            debugPrint("[API] 请求地址:\(url)")
            debugPrint("[API] 请求参数:\(parameters.jsonString ?? "")")
            debugPrint("[API] 请求header:\(headerDic.jsonString ?? "")")
            debugPrint("[API] -----------------------")
        }
        
        dataRequest = sessionManager.request(url, method: method, parameters: nil , encoding: JSONEncoding(), headers: HTTPHeaders.init(headerDic), requestModifier: requestModifier)
        
        dataRequest.responseData { (result: AFDataResponse) in
            guard let code = result.response?.statusCode, code == RequestCode.success.rawValue else {
                
                let retStr = String(data: result.data ?? Data(), encoding: .utf8)
                let code = result.response?.statusCode ?? -9999
                debugPrint("[API] ❌❌❌ event:\(self.eventType) code: \(code) error:\(retStr ?? "")")
                self.handleError(code: code, error: retStr, request: result.request)
                return
            }
            if let data = result.data {
                let retStr = String(data: data, encoding: .utf8) ?? ""
                debugPrint("[API] ✅✅✅ event: \(self.eventType) response \(retStr)")
                self.requestSuccess(retStr)
            } else {
                debugPrint("[API] ❌❌❌ event: \(self.eventType) response data is nil")
                self.handleError(code: RequestCode.serverError.rawValue, error: nil, request: result.request)
            }
        }
        
    }
    
    private func requestSuccess(_ str: String) -> Void {
        CacheUtil.shared.removeCache(id)
        self.success?(str)
        self.success = nil
        self.end?()
        self.end = nil
    }
    
    
    // MARK: 错误处理
    func handleError(code:Int, error: Any?, request: URLRequest?) -> Void {
        // 通过id进行缓存
        CacheUtil.shared.appendCache(RequestCache(id, type: eventType,  req: request))
        self.error?(error, RequestCode(rawValue: code) ?? .unknown)
        self.end?()
        self.end = nil
    }
    
}

extension Dictionary {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        let jsonString = String(data: data, encoding: .utf8)
        return jsonString
    }
    
    var data: Data? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        return data
    }
    
}

extension Data {
    var json: [String: Any]? {
        guard let json = try? JSONSerialization.jsonObject(with: self) else {
            return nil
        }
        return json as? [String : Any]
    }
}
