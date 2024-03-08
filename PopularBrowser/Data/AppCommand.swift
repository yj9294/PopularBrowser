//
//  AppCommand.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation
import UIKit
import Combine
import UniformTypeIdentifiers
import Firebase
import BackgroundTasks

protocol AppCommand {
    func execute(in store: AppStore)
}

class SubscriptionToken {
    var cancelable: AnyCancellable?
    func unseal() { cancelable = nil }
}

extension AnyCancellable {
    func seal(in token: SubscriptionToken) {
        token.cancelable = self
    }
}

struct BrowserCommand: AppCommand {
    func execute(in store: AppStore) {
        store.state.launched.text = ""
        
        let webView = store.state.browser.browser.webView
        
        let goback = webView.publisher(for: \.canGoBack).sink { canGoBack in
            store.state.launched.canGoBack = canGoBack
        }
        
        let goForword = webView.publisher(for: \.canGoForward).sink { canGoForword in
            store.state.launched.canGoForword = canGoForword
        }
        
        let isLoading = webView.publisher(for: \.isLoading).sink { isLoading in
            debugPrint("isloading \(isLoading)")
            store.state.launched.isLoading = isLoading
        }
        
        var start = Date()
        let progress = webView.publisher(for: \.estimatedProgress).sink { progress in
            if progress == 0.1 {
                start = Date()
                store.dispatch(.event(.searchBegian))
            }
            if progress == 1.0 {
                let time = Date().timeIntervalSince1970 - start.timeIntervalSince1970
                store.dispatch(.event(.searchSuccess, ["bro": "\(ceil(time))"]))
            }
            store.state.launched.progress = progress
        }
        
        let isNavigation = webView.publisher(for: \.url).map{$0 == nil}.sink { isNavigation in
            store.state.launched.isNavigation = isNavigation
        }
        
        let url = webView.publisher(for: \.url).compactMap{$0}.sink { url in
            store.state.launched.text = url.absoluteString
        }
        store.publishers = [goback, goForword, progress, isLoading, isNavigation, url]
    }
}

struct HideKeyboardCommand: AppCommand {
    func execute(in store: AppStore) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CopyCommand: AppCommand {
    func execute(in store: AppStore) {
        UIPasteboard.general.setValue(store.state.launched.text, forPasteboardType: UTType.plainText.identifier)
    }
}

struct BrowserSelectItem: AppCommand {
    let item: Browser
    init(_ item: Browser) {
        self.item = item
    }
    func execute(in store: AppStore) {
        store.state.browser.browsers.forEach {
            $0.isSelect = false
        }
        item.isSelect = true
    }
}

struct BrowserDeleteItem: AppCommand {
    let item: Browser
    init(_ item: Browser) {
        self.item = item
    }
    func execute(in store: AppStore) {
        if item.isSelect {
            store.state.browser.browsers = store.state.browser.browsers.filter({
                !$0.isSelect
            })
            store.state.browser.browsers.first?.isSelect = true
        } else {
            store.state.browser.browsers = store.state.browser.browsers.filter({
                $0 != item
            })
        }
    }
}

struct LaunchCommand: AppCommand {
    func execute(in store: AppStore) {
        if store.state.root.progress > 0.0 {
            store.state.root.duration = 12.789
            store.state.root.progress = 0.0
            return
        }
        store.state.root.duration = 12.789
        store.state.root.progress = 0.0
        let token = SubscriptionToken()
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            let progress = store.state.root.progress + 0.01 / store.state.root.duration
            if progress > 1.0 {
                token.unseal()
                store.state.root.progress = 1.0
                store.dispatch(.event(.loadingAD))
                store.dispatch(.adShow(.interstitial) { _ in
                    if store.state.root.progress == 1.0 {
                        store.state.root.selection = .launched
                    }
                })
            } else {
                store.state.root.progress = progress
            }
            if progress > 0.3, store.state.ad.isLoaded(.interstitial) {
                store.state.root.duration = 0.1
            }
        }.seal(in: token)
        store.dispatch(.adLoad(.interstitial))
        store.dispatch(.adLoad(.native, .home))
        store.dispatch(.requestCloak)
        store.dispatch(.requestIP)
    }
}

struct RemoteConfigCommand: AppCommand {
    func execute(in store: AppStore) {
        // 获取本地配置
        if store.state.ad.config == nil {
            let path = Bundle.main.path(forResource: AppUtil.isDebug ? "admob" : "admob_release", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(GADConfig.self, from: data)
                store.dispatch(.adUpdateConfig(config))
                NSLog("[Config] Read local ad config success.")
            } catch let error {
                NSLog("[Config] Read local ad config fail.\(error.localizedDescription)")
            }
        }
        
        // 获取服务器配置
        if store.state.vpn.countryList == nil {
            let path = Bundle.main.path(forResource: "server", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode([VPNCountryModel].self, from: data)
                store.dispatch(.updateVPNCountryList(config))
                NSLog("[Config] Read local server list config success.")
            } catch let error {
                NSLog("[Config] Read local server list config fail.\(error.localizedDescription)")
            }
        }
        
        /// 远程配置
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.fetch { [weak remoteConfig] (status, error) -> Void in
            if status == .success {
                NSLog("[Config] Config fetcher! ✅")
                remoteConfig?.activate(completion: { _, _ in
                    let keys = remoteConfig?.allKeys(from: .remote)
                    NSLog("[Config] config params = \(keys ?? [])")
                    if let remoteAd = remoteConfig?.configValue(forKey: "server").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let serverList = try? JSONDecoder().decode([VPNCountryModel].self, from: data) {
                            NSLog("[Config]  serverlist = \(serverList )")
                            DispatchQueue.main.async {
                                store.dispatch(.updateVPNCountryList(serverList))
                            }
                        } else {
                            NSLog("[Config] Config config 'server' is nil or config not json.")
                        }
                    }
                    
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let adConfig = try? JSONDecoder().decode(GADConfig.self, from: data) {
                            NSLog("[Config]  adConfig = \(adConfig )")
                            DispatchQueue.main.async {
                                store.dispatch(.adUpdateConfig(adConfig))
                            }
                        } else {
                            NSLog("[Config] Config config 'adConfig' is nil or config not json.")
                        }
                    }
                })
            } else {
                NSLog("[Config] config not fetcher, error = \(error?.localizedDescription ?? "")")
            }
        }
    }
}

struct DismissCommand: AppCommand {
    func execute(in store: AppStore) {
        if let topController = AppUtil.rootVC {
            if let presentVC = topController.presentedViewController {
                presentVC.dismiss(animated: true) {
                    topController.dismiss(animated: true)
                }
            } else {
                topController.dismiss(animated: true)
            }
        }
    }
}

struct BackgroundCommand: AppCommand {
    func execute(in store: AppStore) {
        scheduleAppRefresh()
    }
    
    func scheduleAppRefresh() {

    }
}
