//
//  State.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation

struct AppState {
    var root = RootState()
    var launched = LaunchedState()
    var browser = BrowserState()
    var firebase = FirebaseState()
    var ad = ADState()
}

extension AppState {
    struct RootState {
        var adModel: NativeViewModel = .None
        enum Index{
            case launching, launched
        }
        var selection: Index = .launching
        var progress: Double = 0.0
    }
}

extension AppState {
    struct LaunchedState {
        var text: String = ""
        var isLoading: Bool = false
        var canGoBack: Bool = false
        var canGoForword: Bool = false
        var isNavigation: Bool = true
        var progress: Double = 0.0
        enum Index: String, CaseIterable {
            case youtube, facebook, google, twitter, gmail, instagram, amazon, yahoo
            var title: String {
                return "\(self)".capitalized
            }
            var url: String {
                return "https://www.\(self).com"
            }
            var icon: String {
                return "\(self)"
            }
        }
    }
}

extension AppState {
    struct BrowserState {
        var browsers: [Browser] = [.navigation]
        var browser: Browser {
            browsers.filter {
                $0.isSelect
            }.first ?? .navigation
        }
    }
}

extension AppState {
    struct ADState {
        @UserDefault(key: "state.config")
        var config: GADConfig?
       
        @UserDefault(key: "state.limit")
        var limit: GADLimit?
        
        var impressionDate:[GADPosition.Position: Date] = [:]
        
        let ads:[ADLoadModel] = GADPosition.allCases.map { p in
            ADLoadModel(position: p)
        }
        
        func isLoaded(_ position: GADPosition) -> Bool {
            return self.ads.filter {
                $0.position == position
            }.first?.isLoaded == true
        }

        func isLimited(in store: AppStore) -> Bool {
            if limit?.date.isToday == true {
                if (store.state.ad.limit?.showTimes ?? 0) >= (store.state.ad.config?.showTimes ?? 0) || (store.state.ad.limit?.clickTimes ?? 0) >= (store.state.ad.config?.clickTimes ?? 0) {
                    return true
                }
            }
            return false
        }
    }
}

extension AppState {
    struct FirebaseState {
        var item: FirebaseItem = .default
        enum Property: String {
            /// 設備
            case local = "lightBro_borth"
            
            var first: Bool {
                switch self {
                case .local:
                    return true
                }
            }
        }
        
        enum Event: String {
            
            var first: Bool {
                switch self {
                case .open:
                    return true
                default:
                    return false
                }
            }
            
            case open = "lightBro_lun"
            case openCold = "lightBro_clod"
            case openHot = "lightBro_hot"
            case homeShow = "lightBro_impress"
            case homeClick = "lightBro_nav"
            case homeSearch = "lightBro_search"
            case homeClean = "lightBro_clean"
            case cleanAnimationCompletion = "lightBro_cleanDone"
            case cleanAlertShow = "lightBro_cleanToast"
            case tabShow = "lightBro_showTab"
            case webNew = "lightBro_clickTab"
            case shareClick = "lightBro_share"
            case copyClick = "lightBro_copy"
            case searchBegian = "lightBro_requist"
            case searchSuccess = "lightBro_load"
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
