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
            VStack(spacing: 10){
                ScrollView(showsIndicators: false){
                    VStack (spacing: 35){
                        ServerView()
                        VPNStausButton(status: store.state.vpn.state) {
                            store.dispatch(.updateVPNMutaConnect(true))
                            store.dispatch(.vpnConnect)
                            store.dispatch(.loadVPNResultAD)
                        } disconnect: {
                            store.dispatch(.updateVPNMutaDisconnect(true))
                            store.dispatch(.vpnDisconnect)
                            store.dispatch(.loadVPNResultAD)
                        }
                        Spacer()
                    }
                }
                HStack{
                    NativeADView(model: store.state.vpn.ad)
                }.padding(.horizontal, 16).frame(height: 264).padding(.bottom, 20)
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
        }.fullScreenCover(isPresented: $store.state.vpn.isPushServerList, content: {
            NavigationView {
                ServerListView().toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            store.dispatch(.vpnUpdatePushServerView(false))
                            store.dispatch(.event(.serverViewBack))
                        } label: {
                            Image("back")
                        }
                    }
                }
            }
        }).fullScreenCover(isPresented: $store.state.vpn.isPushResult, content: {
            NavigationView {
                VPNConnectResultView().toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            if store.state.root.isUserGo {
                                store.dispatch(.adLoad(.vpnBack))
                                store.dispatch(.adShow(.vpnBack) { _ in
                                    store.dispatch(.vpnUpdatePushResult(false))
                                    loadAndShowVPNAD()
                                })
                                store.dispatch(.event(.vpnBackAD))
                            } else {
                                store.dispatch(.vpnUpdatePushResult(false))
                                loadAndShowVPNAD()
                            }
                        } label: {
                            Image("back")
                        }
                    }
                }
            }
        }).onAppear{
            if store.state.root.coldVPN == true {
                store.dispatch(.event(.coldVPN))
            }
        }
    }
    
    struct ServerView: View {
        @EnvironmentObject var store: AppStore
        var body: some View {
            Button {
                store.dispatch(.vpnUpdatePushServerView(true))
                store.dispatch(.event(.showServerView))
            } label: {
                HStack{
                    HStack(spacing: 12){
                        Image(store.state.vpn.getCountry.image).frame(width: 28, height: 28)
                        Text(store.state.vpn.getCountry.title).font(.system(size: 14))
                        Spacer()
                        Image("arrow_right")
                    }.padding(.horizontal, 16).padding(.vertical, 8).background(Color("#FFF4F7")).cornerRadius(22)
                }.padding(.horizontal,  50).padding(.vertical, 12).foregroundColor(Color("#414141"))
            }.disabled(store.state.vpn.state == .connecting || store.state.vpn.state == .disconnecting)
        }
    }
    
    func loadAndShowVPNAD() {
        store.dispatch(.event(.vpnHomeAD))
        
        store.dispatch(.rootUpdateLoadPostion(.vpnHome))
        store.dispatch(.adDisappear(.vpnHome))
        store.dispatch(.adLoad(.vpnHome, .vpnHome))
        
        if store.state.ad.isLoaded(.vpnHome) {
            store.dispatch(.event(.vpnHomeShowAD))
        }
        if store.state.root.isUserGo {
            store.dispatch(.adLoad(.vpnBack))
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
        @EnvironmentObject var store: AppStore
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
