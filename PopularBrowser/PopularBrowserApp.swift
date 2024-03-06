//
//  PopularBrowserApp.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI
import FBSDKCoreKit
import Firebase
import BackgroundTasks

@main
struct PopularBrowserApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @Environment(\.scenePhase) private var scenePhase
    init() {
        UITabBar.appearance().isHidden = true
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(AppStore())
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.backgroundTask")
        try? BGTaskScheduler.shared.submit(request)
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

            return true
        }
    }
    
    
}
