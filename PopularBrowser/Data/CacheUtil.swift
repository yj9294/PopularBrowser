//
//  CacheUtil.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import Foundation
import WebKit

struct FBPrice: Codable {
    var price: Double
    var currency: String
}

struct RequestCache: Codable, Identifiable {
    var id: String
    var type: String // RequestEventType.rawValue
    
    var parameter: Data
    var query: String
    var header: [String: String]
    var date = Date()
    
    init(_ id: String, type: String, req: URLRequest?) {
        self.id = id
        self.type = type
        parameter = req?.httpBody ?? Data()
        if #available(iOS 16.0, *) {
            query =  req?.url?.query() ?? ""
        } else {
            // Fallback on earlier versions
            if let url = req?.url, let ulrComponenets = URLComponents(url: url , resolvingAgainstBaseURL: false) {
                if let items = ulrComponenets.queryItems {
                    query = items.map({"\($0.name)=\($0.value ??  "")"}).joined(separator: "&")
                } else {
                    query = ""
                }
            } else {
                query = ""
            }
        }
        header = req?.allHTTPHeaderFields ?? [:]
    }
}


class CacheUtil: NSObject {
    static let shared = CacheUtil()
    
    var timer: Timer? = nil
    
    // 是否进入过后台 用于冷热启动判定
    var enterBackgrounded = false
    
    @UserDefault(key: "apis")
    private var caches: [RequestCache]?
    
    @UserDefault(key: "first.install")
    private var install: Bool?
    
    @UserDefault(key: "user.agent")
    private var userAgent: String?
    
    @UserDefault(key: "first.open.count")
    private var firstOpenSuccessCnt: Int?
    
    @UserDefault(key: "first.notification")
    private var firstNoti: Bool?
    
    // fb广告价值回传
    @UserDefault(key: "facebook.price")
    var fbPrice: FBPrice?
    
    @UserDefault(key: "uuid")
    private var uuid: String?
    func getUUID() -> String {
        if let uuid = uuid {
            return uuid
        } else {
            let uuid = UUID().uuidString
            self.uuid = uuid
            return uuid
        }
    }
    
    var connectedNetworkUpload: Bool = false
    override init() {
        super.init()
        self.timer =  Timer.scheduledTimer(withTimeInterval: 65, repeats: true) { [weak self] timer in
            if self?.connectedNetworkUpload == false {
                self?.uploadRequests()
            }
        }
        NotificationCenter.default.addObserver(forName: .connectivityStatus, object: nil, queue: .main) { [weak self] _ in
            if NetworkMonitor.shared.isConnected, self?.connectedNetworkUpload == false {
                // 网络变化 直接上传
                self?.connectedNetworkUpload = true
                self?.uploadRequests()
                DispatchQueue.main.asyncAfter(deadline: .now() + 65) {
                    self?.connectedNetworkUpload = false
                }
            }
        }
    }
    
    
    // MARK - 网络请求失败参数缓存
    func uploadRequests() {
        // 实时清除两天内的缓存
        self.caches = self.caches?.filter({
            $0.date.timeIntervalSinceNow > -2 * 24 * 3600
        })
        // 批量上传
        self.caches?.prefix(25).forEach({
            if $0.type == RequestEventType.install.rawValue {
                Request.installRequest(id: $0.id)
            } else if $0.type == RequestEventType.session.rawValue {
                Request.sessionRequest(id: $0.id)
            } else if $0.type == RequestEventType.ad.rawValue {
                Request.adRequest(id: $0.id)
            } else {
                Request.eventequest(id: $0.id, event: $0.type)
            }
        })
    }
    func appendCache(_ cache: RequestCache) {
        if var caches = caches {
            let isContain = caches.contains {
                $0.id == cache.id
            }
            if isContain {
                return
            }
            caches.append(cache)
            self.caches = caches
        } else {
            self.caches = [cache]
        }
    }
    func removeCache(_ id: String) {
        self.caches = self.caches?.filter({
            $0.id != id
        })
    }
    func cache(_ id: String) -> RequestCache? {
        self.caches?.filter({
            $0.id == id
        }).first
    }
    
    func cacheOfFirstOpenFail() -> Int {
        self.caches?.filter({$0.type == AppState.FirebaseState.Event.open.rawValue}).count ?? 0
    }
    
    
    func cacheOfFirstOpenCount() -> Int {
        firstOpenSuccessCnt ?? 0
    }
    
    func cacheFirstOpenCount() {
        firstOpenSuccessCnt = cacheOfFirstOpenCount() + 1
    }
    
    
    
    // 首次判定 关于install first open enterbackground
    func getInstall() -> Bool {
        let ret = install ?? true
        install = false
        return ret
    }
    func getFirstNoti() -> Bool {
        let ret = firstNoti ?? true
        return ret
    }
    func updateFirstNoti() {
        firstNoti = false
    }
    
    
    func enterBackground() {
        enterBackgrounded = true
    }
    
    
    // userAgent
    func getUserAgent() -> String {
        if Thread.isMainThread, self.userAgent == nil {
            self.userAgent = UserAgentFetcher().fetch()
        } else if let userAgent = self.userAgent {
            return userAgent
        }
        return ""
    }

    func uploadFirstOpenSuccess() {
        firstOpenSuccessCnt =  (firstOpenSuccessCnt ?? 0) + 1
    }
    
    func getFirstOpenCnt() -> Int {
        firstOpenSuccessCnt ?? 0
    }
    
    func needUploadFBPrice() -> Bool {
        NSLog("[FB+Adjust] 当前正在积累广告价值 总价值： \(fbPrice?.price ?? 0) 单位：\(fbPrice?.currency ?? "")")
        let ret = (fbPrice?.price ?? 0.0) > 0.01
        if ret {
            // 晴空
            NSLog("[FB+Adjust] 当前广告价值达到要求进行上传 并清空本地 总价值： \(fbPrice?.price ?? 0) 单位：\(fbPrice?.currency ?? "")")
            fbPrice = nil
        }
        return ret
    }
    
    func addFBPrice(price: Double, currency: String) {
        if let fbPrice = fbPrice, fbPrice.currency == currency {
            self.fbPrice = FBPrice(price: fbPrice.price + price, currency: currency)
        } else {
            fbPrice = FBPrice(price: price, currency: currency)
        }
    }
    
}


@propertyWrapper
struct UserDefault<T: Codable> {
    var value: T?
    let key: String
    init(key: String) {
        self.key = key
        self.value = UserDefaults.standard.getObject(T.self, forKey: key)
    }
    
    var wrappedValue: T? {
        set  {
            value = newValue
            UserDefaults.standard.setObject(value, forKey: key)
            UserDefaults.standard.synchronize()
        }
        
        get { value }
    }
}

extension UserDefaults {
    func setObject<T: Codable>(_ object: T?, forKey key: String) {
        let encoder = JSONEncoder()
        guard let object = object else {
            debugPrint("[US] object is nil.")
            self.removeObject(forKey: key)
            return
        }
        guard let encoded = try? encoder.encode(object) else {
            debugPrint("[US] encoding error.")
            return
        }
        self.setValue(encoded, forKey: key)
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = self.data(forKey: key) else {
            debugPrint("[US] data is nil for \(key).")
            return nil
        }
        guard let object = try? JSONDecoder().decode(type, from: data) else {
            debugPrint("[US] decoding error.")
            return nil
        }
        return object
    }
}

public final class UserAgentFetcher: NSObject {
    
    private let webView: WKWebView = WKWebView(frame: .zero)
    
    @objc
    public func fetch() -> String {
        dispatchPrecondition(condition: .onQueue(.main))

        var result: String?
        
        webView.evaluateJavaScript("navigator.userAgent") { response, error in
            if error != nil {
                result = ""
                return
            }
            
            result = response as? String ?? ""
        }

        while (result == nil) {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        return result ?? ""
    }
    
}
