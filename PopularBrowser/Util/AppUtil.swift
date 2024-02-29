//
//  AppUtil.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import Foundation
import UIKit

struct AppUtil {
    // MARK: App信息
    /// 应用名称
    static let name: String = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "PopularBrowser"
    /// 版本号
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    /// build号
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"
    /// 包名
    static let bundle = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "com.lightforyou.cloud.application.LightVPN"
    
    static let group = "group." + bundle
    
    static let proxy = bundle + ".Proxy"
    
    static let localCountry = Locale.current.regionCode
    
    static let isDebug = (Bundle.main.bundleIdentifier ?? "") != "com.popularSearch.browsers.fast"
    
    static var rootVC: UIViewController? {
        (UIApplication.shared.connectedScenes.filter({$0 is UIWindowScene}).first as? UIWindowScene)?.windows.filter({$0.isKeyWindow}).first?.rootViewController
    }
    /// vpn链接超时时长
    static let connectTimeout: Double = 4.0
    /// 链接/断开 动效时长
    static let animationTimeout = 3.0
    /// icmp链接超时时长
    static let pingTimeout = 2.5
}
