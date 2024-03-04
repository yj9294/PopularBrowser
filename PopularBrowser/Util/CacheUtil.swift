//
//  CacheUtil.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import Foundation

class CacheUtil {
    static let shared = CacheUtil()
    private var serverList: [VPNCountryModel] = []
    func getServerList() -> [VPNCountryModel] {
        if !serverList.isEmpty {
            return serverList
        }
        if let serverList = UserDefaults.standard.getObject([VPNCountryModel].self, forKey: "vpn.serverce"), !serverList.isEmpty{
            self.serverList = serverList
            return serverList
        }
        let path = Bundle.main.path(forResource: "server", ofType: "json")
        let url = URL(fileURLWithPath: path!)
        if let localData = try? Data(contentsOf: url) {
            serverList = (try? JSONDecoder().decode([VPNCountryModel].self, from: localData)) ?? []
            UserDefaults.standard.setObject(serverList, forKey: "vpn.serverce")
            debugPrint("[VPN] 读取本地数据default server")
        }
        return serverList
    }
    
    private var password: String = ""
    func getPasword() -> String {
        if let password = UserDefaults.standard.getObject(String.self, forKey: "password") {
            self.password = password
            return password
        }
        return "K49qpWT_sU8ML1+m"
    }
    func savePassword(_ psw: String) {
        self.password = psw
        UserDefaults.standard.setObject(psw, forKey: "password")
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
