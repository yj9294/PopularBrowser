//
//  VPNConnectResultView.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import SwiftUI

struct VPNConnectResultView: View {
    @EnvironmentObject var store: AppStore
    var icon: String {
        store.state.result.isConnected ? "vpn_result_connect" : "vpn_result_disconnect"
    }
    var title: String {
        store.state.result.isConnected ? "Successful Connection" : "Successful Disconnection"
    }
    var body: some View {
        VStack(spacing: 20){
            Image(icon).padding(.vertical, 16)
            VStack(spacing: 10){
                Text(title).font(.system(size: 16)).foregroundColor(Color.black)
                Text(store.state.vpn.serverTitle).font(.system(size: 13)).foregroundColor(Color("#AFAFAF"))
            }
            Spacer()
        }.navigationBarBackButtonHidden()
    }
}

struct VPNConnectResultView_Previews: PreviewProvider {
    static var previews: some View {
        VPNConnectResultView()
    }
}
