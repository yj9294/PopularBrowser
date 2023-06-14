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
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            willEnterForeground()
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            didEnterBackground()
        }
    }
}

extension ContentView {
    func launched() {
        store.dispatch(.rootSelection(.launched))
    }
    
    func willEnterForeground() {
        store.dispatch(.rootSelection(.launching))
        store.dispatch(.event(.openHot))
    }
    
    func didEnterBackground() {
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppStore())
    }
}
