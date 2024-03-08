//
//  RequestCommand.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import Foundation
import Reachability
import UIKit
import AdSupport

//{
//  "ip": "166.0.236.212",
//  "city": "Fremont",
//  "region": "California",
//  "country": "US",
//  "loc": "37.5483,-121.9886",
//  "org": "AS6939 Hurricane Electric LLC",
//  "postal": "94536",
//  "timezone": "America/Los_Angeles",
//  "readme": "https://ipinfo.io/missingauth"
//}
struct IPResponse: Codable {
    var ip: String?
    var city: String?
    var country: String?
}

// 请求当前本地IP
struct RequestIPCommand: AppCommand {
    func execute(in store: AppStore) {
        requestIP(in: store)
    }
    
    func requestIP(in store: AppStore, retry: Int = 3) {
        if retry == 0 {
            debugPrint("[IP] 重试超过3次了")
        }
        let token = SubscriptionToken()
        debugPrint("[IP] 开始请求")
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://ipinfo.io/json")!).map({
            $0.data
        }).eraseToAnyPublisher().decode(type: IPResponse.self, decoder: JSONDecoder()).sink { complete in
            if case .failure(let error) = complete {
                debugPrint("[IP] err:\(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.requestIP(in: store, retry:  retry - 1)
                }
            }
            token.unseal()
        } receiveValue: { response in
            debugPrint("[IP] 当前国家:\(response.country ?? "")")
            if response.country == "CN" {
                store.dispatch(.rootUpdateIPError(true))
            }
        }.seal(in: token)
    }

}

// 请求 cloak
struct RequestClakCOmmand: AppCommand {
    func execute(in store: AppStore) {
        requestCloak(in: store)
    }
    
    func requestCloak(in store: AppStore, retry: Int = 3) {
        if retry == 0 {
            debugPrint("[cloak] 重试超过三次了")
            return
        }
        
        if let go = store.state.root.userGo {
            debugPrint("[cloak] 当前已有cloak 是否是激进模式: \(go)")
            return
        }
        
        let token = SubscriptionToken()
        var url = "https://many.fastpopularsearch.com/lavabo/teutonic"
        var params: [String: String] = [:]
        let ts = Date().timeIntervalSince1970 * 1000.0
        params["harvest"] = CacheUtil.shared.getUUID()
        params["hartman"] = "\(Int(ts))"
        params["damocles"] = UIDevice.current.model
        params["proctor"] = Bundle.main.bundleIdentifier
        params["donna"] = UIDevice.current.systemVersion
        params["risky"] = UIDevice.current.identifierForVendor?.uuidString
        params["sidemen"] = ""
        params["mustache"] = ""
        params["english"] = "yarn"
        params["patient"] =  ASIdentifierManager.shared().advertisingIdentifier.uuidString
        params["brought"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        url.append("?")
        let ret = params.keys.map { key in
            "\(key)=\(params[key] ?? "")"
        }.joined(separator: "&")
        url.append(ret)
        if let query = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url = query
        }
        debugPrint("[cloak] start request: \(url)")
        URLSession.shared.dataTaskPublisher(for: URL(string: url)!).map({
            String(data: $0.data, encoding: .utf8)
        }).eraseToAnyPublisher().sink { complete in
            if case .failure(let error) = complete {
                debugPrint("[cloak] err:\(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.requestCloak(in: store, retry: retry - 1)
                }
            }
            token.unseal()
        } receiveValue: { data in
            debugPrint("[cloak] \(data ?? "")")
            store.dispatch(.rootUpdateUserGo(data == "yokohama"))
        }.seal(in: token)
    }
}

