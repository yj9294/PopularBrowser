//
//  PopularBrowserApp.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI
import FBSDKCoreKit
import Firebase

@main
struct PopularBrowserApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        UITabBar.appearance().isHidden = true
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(AppStore())
        }
    }
    
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            ApplicationDelegate.shared.application(
                application,
                didFinishLaunchingWithOptions: launchOptions
            )
            VPNUtil.shared.load()
            VPNUtil.shared.prepareForLoading {
                switch VPNUtil.shared.managerState {
                case .ready:
//                    self.onStateChangedTo(state: VPNUtil.shared.vpnState)
                    break
                default:
                    break
                }
                debugPrint("[VPN MANAGER] prepareForLoading manager state: \(VPNUtil.shared.managerState), VPN state: \(VPNUtil.shared.vpnState)")
            }
            return true
        }
              
        func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool {
            ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )
        }
    }
}
