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

struct RemoteConfigCommand: AppCommand {
    func execute(in store: AppStore) {
        // 获取本地配置
        if store.state.ad.config == nil {
            let path = Bundle.main.path(forResource: "admob", ofType: "json")
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
                    if let remoteAd = remoteConfig?.configValue(forKey: "adConfig").stringValue {
                        // base64 的remote 需要解码
                        let data = Data(base64Encoded: remoteAd) ?? Data()
                        if let remoteADConfig = try? JSONDecoder().decode(GADConfig.self, from: data) {
                            // 需要在主线程
                            DispatchQueue.main.async {
                                store.dispatch(.adUpdateConfig(remoteADConfig))
                            }
                        } else {
                            NSLog("[Config] Config config 'ad_config' is nil or config not json.")
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
        if let topController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
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

