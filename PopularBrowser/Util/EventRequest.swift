//
//  EventRequest.swift
//  BPDeliverer
//
//  Created by yangjian on 2023/12/19.
//

import Foundation
import WebKit
import AdSupport
import Adjust

extension Request {

    class func installRequest(id: String, completion: ((Bool)->Void)? = nil) {
        var param: [String: Any] = [:]
        // 系统构建版本，Build.ID， 以 build/ 开头
        param["keelson"] = "Build/\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "1")"
        // webview中的user_agent, 注意为webview的，android中的useragent有;wv关键字
        param["dominion"] = CacheUtil.shared.getUserAgent()
        // 用户是否启用了限制跟踪，0：没有限制，1：限制了；枚举值，映射关系：{“mediate”: 0, “amigo”: 1}
        // 00000000-0000-0000-0000-000000000000
        param["squint"] = ASIdentifierManager.shared().advertisingIdentifier.uuidString == "00000000-0000-0000-0000-000000000000" ? "mediate" : "amigo"
        // 引荐来源网址点击事件发生时的客户端时间戳（以秒为单位）,https://developer.android.com/google/play/installreferrer/igetinstallreferrerservice
        param["shiv"] = Int(Date().timeIntervalSince1970)
        // 应用安装开始时的客户端时间戳（以秒为单位）,https://developer.android.com/google/play/installreferrer/igetinstallreferrerservice
        param["criminal"] = Int(Date().timeIntervalSince1970)
        // 引荐来源网址点击事件发生时的服务器端时间戳（以秒为单位）,
        param["bridal"] = Int(Date().timeIntervalSince1970)
        param["tech"] = Int(Date().timeIntervalSince1970)
        param["bog"] = Int(Date().timeIntervalSince1970)
        param["neuroses"] = Int(Date().timeIntervalSince1970)
        
        debugPrint("[tba] 开始上报 install ")
        Request(id: id, parameters: ["ransack":param]).netWorkConfig { req in
            req.method = .post
            req.eventType = RequestEventType.install.rawValue
        }.startRequestSuccess { _ in
            debugPrint("[tba] 上报 install 成功 ✅✅✅")
            completion?(true)
        }.error { obj, code in
            debugPrint("[tba] 上报 install 失败 ❌❌❌")
            completion?(false)
        }
    }
    
    class func sessionRequest(id: String, completion: ((Bool)->Void)? = nil) {
        let param: [String: Any] = [:]
        debugPrint("[tba] 开始上报 session ")
        Request(id: id, parameters: ["marry": param]).netWorkConfig { req in
            req.method = .post
            req.eventType = RequestEventType.session.rawValue
        }.startRequestSuccess { _ in
            debugPrint("[tba] 上报 session 成功 ✅✅✅")
            completion?(true)
        }.error { obj, code in
            debugPrint("[tba] 上报 session 失败 ❌❌❌")
            completion?(false)
        }
    }
    
    class func adRequest(id: String, ad: ADBaseModel? = nil, completion: ((Bool)->Void)? = nil) {
        var param: [String: Any] = [:]
        param["goldberg"] = (ad?.price ?? 0) * 1000000
        param["clavicle"] = ad?.currency ?? "USD"
        param["heusen"] = ad?.network ?? ""
        param["much"] = "admob"
        param["winston"] = ad?.model?.theAdID ?? ""
        param["orestes"] = ad?.position.rawValue
        param["stubborn"] = ""
        param["several"] = ad?.position.isNative == true ? "native" : "interstitial"
        param["cicada"] = ad?.loadIP ?? ""
        param["spin"] = ad?.impressIP ?? ""
        
        param["merit"] = "curtis"
        debugPrint("[tba] 开始上报 ad ")
        Request(id: id, parameters: param).netWorkConfig { req in
            req.method = .post
            req.eventType = RequestEventType.ad.rawValue
        }.startRequestSuccess { _ in
            debugPrint("[tba] 上报 ad 成功 ✅✅✅")
            completion?(true)
        }.error { obj, code in
            debugPrint("[tba] 上报 ad 失败 ❌❌❌")
            completion?(false)
        }
    }
    
    class func eventequest(id: String, event: String, value: [String: Any]? = nil, completion: ((Bool)->Void)? = nil) {
        var param: [String: Any] = [:]
        param["merit"] = event
        value?.keys.forEach({ key in
            param["saxon_\(key)"] = value?[key]
        })
        debugPrint("[tba] 开始上报 \(event) param:\(value ?? [:])")
        Request(id: id, parameters: param).netWorkConfig { req in
            req.method = .post
            req.eventType = event
        }.startRequestSuccess { _ in
            debugPrint("[tba] 上报 \(event) 成功 ✅✅✅")
            CacheUtil.shared.cacheFirstOpenCount()
            completion?(true)
        }.error { obj, code in
            debugPrint("[tba] 上报 \(event) 失败 ❌❌❌")
            completion?(false)
        }
    }
}

enum RequestEventType: String, Codable {
    // 安装事件
    case install
    case session
    case ad
    case firstOpen = "first_open"
}
