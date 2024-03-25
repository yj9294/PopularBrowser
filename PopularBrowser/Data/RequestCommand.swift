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
        if store.state.vpn.state == .connected {
            return
        }
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
            store.dispatch(.rootUpdateIP(response.ip ?? ""))
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

// 安装事件
struct RequestInstallEventCommand: AppCommand {
    func execute(in store: AppStore) {
        if CacheUtil.shared.getInstall() {
            installRequest(retry: true)
        }
    }
    
    func installRequest(id: String = UUID().uuidString,retry: Bool) {
        Request.installRequest(id: id) { ret in
            if !ret, retry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if CacheUtil.shared.cache(id) != nil {
                        debugPrint("[tba] 开始重试上报 install 事件")
                        installRequest(id: id ,retry: false)
                    }
                }
            }
        }
    }
}

// session事件
struct RequestSessionEventCommand: AppCommand {
    func execute(in store: AppStore) {
        sessionRequest(retry: true)
    }
    
    func sessionRequest(id: String = UUID().uuidString,retry: Bool) {
        Request.sessionRequest(id: id) { ret in
            if !ret, retry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if CacheUtil.shared.cache(id) != nil {
                        debugPrint("[tba] 开始重试上报 session 事件")
                        sessionRequest(id: id ,retry: false)
                    }
                }
            }
        }
    }
}

// ad 事件
struct RequestADEventCommand: AppCommand {
    let ad: ADBaseModel?
    init(_ ad: ADBaseModel? = nil) {
        self.ad = ad
    }
    func execute(in store: AppStore) {
        adRequest(retry: true)
    }
    
    func adRequest(id: String = UUID().uuidString, retry: Bool) {
        Request.adRequest(id: id, ad: ad) { ret in
            if !ret, retry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if CacheUtil.shared.cache(id) != nil {
                        debugPrint("[tba] 开始重试上报 ad 事件")
                        adRequest(id: id, retry: false)
                    }
                }
            }
        }
    }
}


// first open 事件
struct RequestFirstOpenEventCommand: AppCommand {
    func execute(in store: AppStore) {
        var retry = 6
        // 失败缓存的 first open
        if CacheUtil.shared.cacheOfFirstOpenFail() > 0 {
            retry = 6 - CacheUtil.shared.cacheOfFirstOpenFail()
        } else {
            retry = 6 - CacheUtil.shared.cacheOfFirstOpenCount()
        }
        if retry <= 0 {
            return
        }
        self.firstOpenRequest(retry: true) { ret in
            if ret {
                retry -= 1
            }
        }
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            if retry <= 0 || CacheUtil.shared.cacheOfFirstOpenFail() >= 6 {
                timer.invalidate()
                return
            }
            self.firstOpenRequest(retry: true) { ret in
                if ret {
                    retry -= 1
                }
            }
        }
    }
    
    func firstOpenRequest(id: String = UUID().uuidString, retry: Bool, completion:((Bool)->Void)? = nil) {
        Request.eventequest(id: id, event: RequestEventType.firstOpen.rawValue) { ret in
            if ret {
                completion?(true)
            } else {
                if retry {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if CacheUtil.shared.cache(id) != nil {
                            debugPrint("[tba] 开始重试上报 firstOpen 事件")
                            firstOpenRequest(id: id, retry: false, completion: completion)
                        } else {
                            completion?(true)
                        }
                    }
                } else {
                    completion?(false)
                }
            }
        }
    }
}

// 普通事件
struct RequestEventCommand: AppCommand {
    let name: String
    let value: [String: Any]?
    func execute(in store: AppStore) {
        self.eventRequest(retry: true)
    }
    
    func eventRequest(id: String = UUID().uuidString,retry: Bool) {
        Request.eventequest(id: id, event: name, value: value) { ret in
            if !ret, retry {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if CacheUtil.shared.cache(id) != nil {
                        debugPrint("[tba] 开始重试上报 \(name) 事件, 参数\(value ?? [:])")
                        eventRequest(id: id ,retry: false)
                    }
                }
            }
        }
    }
}

struct DecodeMode: Codable {
    var ft: String
    var pp: String
}

struct CountryModel: Codable, Equatable, Hashable {
    var hCountries: [Country] // 高区间服务器
    var lCountries: [Country] // 低区间服务器
    var hRate: Int // 高区间概率
    var lRate: Int // 低区间概率
    struct Country: Codable, Equatable, Hashable, Identifiable {
        let id = UUID().uuidString
        var ip: String
        var weight: Int
        var code: String
        var country: String
        var city: String
        var config: [Config]
        var delay: Double?
        struct Config: Codable, Equatable, Hashable {
            var psw: String
            var method: String
            var port: Int
            
            enum CodingKeys: String, CodingKey {
                case psw = "everything"
                case method = "others"
                case port = "either"
            }
        }
        enum CodingKeys: String, CodingKey {
            case ip = "return"
            case weight = "chair"
            case code = "good"
            case country = "make"
            case city = "nor"
            case config = "executive"
        }
        static let smart: Self = Country(ip: "", weight: 0, code: "fastest", country: "", city: "Smart server", config: [])
        var isSmart: Bool { self == .smart }
        var title: String {
            return self.isSmart ? city : "\(country)-\(city)"
        }
        var icon: String {
            return "country_\(code)"
        }
        
        var image: String {
            if UIImage(named: icon) == nil {
                return "country_unknow"
            } else {
                return icon
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case hCountries = "across"
        case lCountries = "culture"
        case hRate = "show"
        case lRate = "owner"
    }
    
    static let `default`: Self = CountryModel(hCountries: [], lCountries: [], hRate: 0, lRate: 0)
    
    func allModels() -> [Country] {
        [.smart] + hCountries + lCountries
    }
    
    func models() -> [Country] {
        debugPrint("[server] 开始查找 区间 服务器集群")
        debugPrint("[server] 开始随机")
        var h = hRate
        var l = lRate
        if hCountries.isEmpty, lCountries.isEmpty {
            debugPrint("[server] 服务器配置错误, 无任何服务器")
            return[]
        } else if hCountries.isEmpty {
            h = 0
            l = 100
            debugPrint("[server] 高区间未配置服务器, 调整低区间概率为100")
        } else if lCountries.isEmpty {
            h = 100
            l = 0
            debugPrint("[server] 低区间未配置服务器, 调整高区间概率为100")
        }
        let randomKey = arc4random() % 100
        debugPrint("[server] 随机值: \(randomKey) 高:\(h) 低\(l)")
        if randomKey < h {
            debugPrint("[server] \(randomKey)小于高区间概率: \(h) 使用高区间服务器")
            return hCountries
        } else {
            debugPrint("[server] \(randomKey)不小于高区间概率: \(h) 使用低区间服务器")
            return lCountries
        }
    }
    
    static func repeatCountry(with models: [Country]) -> [Country] {
        debugPrint("[server] 开始去重 country 服务器 \(models)")
        let uniqueObjects = models.reduce(into: [String: Int]()) { uniqueObjects, object in
            if let existingValue = uniqueObjects[object.ip] {
                uniqueObjects[object.ip] = existingValue + object.weight
            } else {
                uniqueObjects[object.ip] = object.weight
            }
        }

        // 将结果转换为包含对象的数组
        let result = uniqueObjects.compactMap { obj in
            if var model: Country = models.filter({$0.ip == obj.key}).first {
                model.weight = obj.value
                return model
            }
            return nil
        }

        // 打印结果
        debugPrint("[server] 去重完 country 服务器: result:\(result)")
        return result
    }
    
    static func smartModel(with models: [Country]) -> Country? {
        debugPrint("[server] 开始查找 smart 服务器")
        debugPrint("[server] 开始随机")
        let totalWeight: Double = Double(models.map({$0.weight}).reduce(0, +))
        let random = Double(arc4random() % 100)
        debugPrint("[server] 随机数：\(Int(random))")
        var start = 0.0
        var end = 0.0
        return models.filter{ m in
            let alt = Double(m.weight) / totalWeight * 100
            end = start + alt
            if random >= start, random < end {
                debugPrint("[server] 选中 ip: \(m.ip) 权重: \(m.weight), \(Int(alt))%")
                start = end
                return true
            } else {
                debugPrint("[server] ip: \(m.ip) 权重: \(m.weight), \(Int(alt))%")
                start = end
                return false
            }
        }.first
    }
}

// 获取ip池
struct RequestServersCommand: AppCommand {
    func execute(in store: AppStore) {
        requestServerList(in: store)
    }
    
    func requestServerList(in store: AppStore) {
        let token = SubscriptionToken()
        let url = URL(string: AppUtil.isDebug ? "https://test.fastpopularsearch.com/lpc/silhz/" : "https://prod.fastpopularsearch.com/lpc/silhz/")!
        if let request = try? URLRequest(url: url, method: .post, headers: ["FT": AppUtil.bundle, "PP": AppUtil.version]) {
            debugPrint("[server] 开始请求 url:\(url) method:\(request.httpMethod ?? "") header:\(request.headers)")
            URLSession.shared.dataTaskPublisher(for: request).map({
                $0.data
            }).eraseToAnyPublisher().decode(type: DecodeMode.self, decoder: JSONDecoder()).sink { complete in
                if case .failure(let error) = complete {
                    debugPrint("[server] err:\(error)")
                }
                token.unseal()
            } receiveValue: { data in
                var ft = data.ft.replacingOccurrences(of: data.pp, with: "")
                ft = String(ft.reversed())
                if let baseString = ft.base64DecodeString {
                    debugPrint("[server] \(baseString)")
                    if let bData = baseString.data(using: .utf8), let model = try? JSONDecoder().decode(CountryModel.self, from: bData) {
                        store.dispatch(.updateVPNCountryList(model))
                    } else {
                        debugPrint("[server] error: decode json error")
                    }
                } else {
                    debugPrint("[server] error: decode base64 error")
                }
            }.seal(in: token)
        }
    }
    
}

extension String {
    var base64DecodeString: String? {
        if let decodeData = Data(base64Encoded: self) {
            if let decodeString = String(data: decodeData, encoding: .utf8) {
                return decodeString
            }
            return nil
        }
        return nil
    }
}
