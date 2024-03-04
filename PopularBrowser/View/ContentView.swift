//
//  ContentView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        TabView(selection: $store.state.root.selection) {
            LaunchingView(launched: launched).tag(AppState.RootState.Index.launching)
            LaunchedView().tag(AppState.RootState.Index.launched)
        }.fullScreenCover(isPresented: $store.state.root.showCNError, content: {
            Text("The laws and policies of Chinese Mainland do not support the use of VPN").padding(.horizontal, 60).multilineTextAlignment(.center).onAppear{
                Task{ @MainActor in
                    try await Task.sleep(nanoseconds:3_000_000_000)
                    store.dispatch(.rootUpdateIPError(false))
                }
            }
        }).onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            willEnterForeground()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            didEnterBackground()
        }.onReceive(NotificationCenter.default.publisher(for: .nativeAdLoadCompletion)) { notification in
            receiveAD(notification)
        }
    }
}

extension ContentView {
    func launched() {
        store.dispatch(.rootSelection(.launched))
        store.dispatch(.adLoad(.interstitial))
        store.dispatch(.adLoad(.native, .home))
    }
    
    func willEnterForeground() {
        // vpn权限进入后台不走热启动
        if !store.state.vpn.isPermissonAlert {
            store.dispatch(.dismiss)
            store.dispatch(.rootSelection(.launching))
            store.dispatch(.event(.openHot))
        }
        store.dispatch(.rootUpdateBackground(false))
        store.dispatch(.rootUpdateTime(-1))
    }
    
    func didEnterBackground() {
        // vpn权限进入后台不走热启动
        if !store.state.vpn.isPermissonAlert {
            store.dispatch(.dismiss)
            store.dispatch(.rootSelection(.launching))
        }
        store.dispatch(.rootUpdateBackground(true))
        store.dispatch(.rootUpdateTime(600))
    }
    
    func receiveAD(_ noti: Notification) {
        if let ad = noti.object as? NativeViewModel {
            store.dispatch(.adModel(ad))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppStore())
    }
}
