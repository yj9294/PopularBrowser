//
//  VPNView.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import SwiftUI

struct VPNView: View {
    
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        ZStack{
            VStack(spacing: 35){
                Text(store.state.vpn.serverTitle).multilineTextAlignment(.center).font(.system(size: 16)).foregroundStyle(.linearGradient(colors: [Color("#F3A640"), Color("#FA44B2")], startPoint: .leading, endPoint: .trailing)).padding(.vertical, 22)
                VPNStausButton(status: store.state.vpn.state) {
                    store.dispatch(.updateVPNMutaConnect(true))
                    store.dispatch(.vpnConnect)
                } disconnect: {
                    store.dispatch(.vpnDisconnect)
                }
                Spacer()
            }
            
            // 弹窗
            if store.state.vpn.isAlert {
                AlertView(text: store.state.vpn.alertMessage).onAppear{
                    Task {
                        if !Task.isCancelled {
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            store.dispatch(.dismissAlert)
                        }
                    }
                }
            }
            
            // push result
            if store.state.vpn.isPushResult {
                NavigationLink(isActive: $store.state.vpn.isPushResult) {
                    VPNConnectResultView().toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                store.dispatch(.vpnUpdatePushResult(false))
                            } label: {
                                Image("back")
                            }
                        }
                    }
                } label: {
                    EmptyView()
                }
            }
        }.onAppear{
            if store.state.root.coldVPN == true {
//                store.dispatch(.rootUpdateColdVPN(false))
                store.dispatch(.event(.coldVPN))
            }
        }
    }
    
    struct AlertView: View {
        let text: String
        var body: some View {
            ZStack{
                Color.black.opacity(0.7)
                VStack{
                    HStack{
                        Spacer()
                        Text(text).foregroundColor(.black).padding(.all,16)
                        Spacer()
                    }.background(.white).cornerRadius(12)
                }.padding(.horizontal, 60)
            }
        }
    }
    
    struct VPNStausButton: View{
        @State private var rotation: Double = 0.0
        let status: VPNUtil.VPNState
        let connect: ()->Void
        let disconnect: ()->Void
        var body: some View {
            VStack(spacing: 30){
                Button {
                    action()
                } label: {
                    ZStack{
                        Image("vpn_status")
                        Text(status.title).foregroundColor(.white).font(.system(size: 20))
                    }
                }.disabled(status == .connecting || status == .disconnecting)
                HStack{
                    if status == .disconnected || status == .idle {
                        HStack{
                            Button {
                                action()
                            } label: {
                                Image("vpn_connect")
                            }
                            Spacer()
                        }
                    } else if status == .connecting || status == .disconnecting {
                        HStack{
                            Spacer()
                            ZStack{
                                Image("vpn_connecting_1")
                                Image("vpn_connecting_2").rotationEffect(Angle(degrees: rotation))
                                    .onAppear() {
                                        withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                                            self.rotation = 360.0
                                        }
                                    }.onDisappear{
                                        self.rotation = 0.0
                                    }
                            }
                            Spacer()
                        }
                    } else if status == .connected {
                        HStack{
                            Spacer()
                            Button {
                                action()
                            } label: {
                                Image("vpn_connected")
                            }
                        }
                    }
                }.padding(.all, 4).background(Image("vpn_button_bg").resizable()).frame(width: 272, height: 72)
            }
        }
        
        func action() {
            if status == .disconnected || status == .idle {
                connect()
            } else if status == .connected {
                disconnect()
            }
        }
    }
}

extension VPNView {
    
    func viewDidAppear() {
        
    }
    
}