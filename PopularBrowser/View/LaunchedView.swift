//
//  LaunchedView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI
import SheetKit
import AppTrackingTransparency

struct LaunchedView: View {
    @EnvironmentObject var store: AppStore

    let columns:[GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var text: String {
        store.state.launched.text
    }
    var isLoading: Bool {
        store.state.launched.isLoading
    }
    var canGoBack: Bool {
        store.state.launched.canGoBack
    }
    var canGoForword: Bool {
        store.state.launched.canGoForword
    }
    
    var isNavigation: Bool {
        store.state.launched.isNavigation
    }
    
    var progress: Double {
        store.state.launched.progress
    }
    
    var isTabShow: Bool {
        store.state.launched.isTabShow
    }
    
    var isGuideShow: Bool {
        store.state.launched.isShowGuide
    }
    
    var isVPNVShow: Bool {
        store.state.launched.pushVPNView
    }
    
    var body: some View {
        GeometryReader { _ in
            NavigationView {
                ZStack{
                    // 首页
                    VStack{
                        
                        // 搜索框 界面
                        ProgressView(value: progress, total: 1.0).accentColor(Color("#FA44B2")).opacity(isLoading ? 1.0 : 0.0)
                        HStack{
                            TextField("Seaech or enter address", text: $store.state.launched.text).padding(.vertical, 18).padding(.leading, 20)
                            Button(action: search) {
                                Image(isLoading ? "search_stop" : "search").padding(.trailing, 20)
                            }
                        }.background(RoundedRectangle(cornerRadius: 28).stroke(Color("#8A8A8A"), lineWidth: 1)).padding(.horizontal, 24)
                        
                        // 浏览器界面
                        VStack(spacing: 10){
                            if isNavigation {
                                Button {
                                    store.dispatch(.homeUpdatePushVPNView(true))
                                } label: {
                                    Image("vpn_title")
                                }.padding(.vertical, 35)
                                LazyVGrid(columns: columns, spacing: 20){
                                    ForEach(AppState.LaunchedState.Index.allCases, id: \.self) { index in
                                        Button(action: {
                                            searchIndex(index)
                                        }, label: {
                                            VStack(spacing: 12){
                                                Image(index.icon)
                                                Text(index.title)
                                                    .foregroundColor(Color("#333333"))
                                                    .font(.system(size: 13.0))
                                            }
                                        })
                                    }
                                }.padding(.horizontal, 16).padding(.top, 20)
                                if !isTabShow, !isGuideShow, !isVPNVShow {
                                    HStack{
                                        NativeADView(model: store.state.root.adModel)
                                    }.padding(.horizontal, 16).frame(height: 120)
                                }
                            } else if !isTabShow {
                                WebView(webView: store.state.browser.browser.webView)
                            }
                        }
                        Spacer()
                        
                        // 底部 按钮
                        HStack{
                            Button(action: goBack) {
                                Image(canGoBack ? "left" : "left_1")
                            }
                            Spacer()
                            Button(action: goForword) {
                                Image(canGoForword ? "right" : "right_1")
                            }
                            Spacer()
                            Button(action: {
                                clean()
                            }, label: {
                                Image("clean")
                            })
                            Spacer()
                            Button(action: tab) {
                                ZStack {
                                    Image("tab")
                                    Text("\(store.state.browser.browsers.count)").font(.system(size: 11, weight: .bold)).padding(.trailing, 6).padding(.top, 5)
                                }
                            }.foregroundColor(Color("#333333"))
                            Spacer()
                            Button(action: setting) {
                                Image("setting")
                            }
                        }.padding(.horizontal, 20).frame(height: 60)
                    }.background(Color("#F2F3F4").ignoresSafeArea()).onAppear{viewDidAppear()}
                    
                    // vpn 引导界面
                    if isGuideShow {
                        GuideView {
                            store.dispatch(.homeUpdateShowGuide(false))
                            store.dispatch(.homeUpdatePushVPNView(true))
                            store.dispatch(.vpnConnect)
                            store.dispatch(.loadVPNResultAD)
                            store.dispatch(.updateVPNMutaConnect(true))
                            store.dispatch(.event(.vpnGuideOK))
                        } skip: {
                            store.dispatch(.homeUpdateShowGuide(false))
                            store.dispatch(.event(.vpnGuideSkip))
                            loadAndShowHomeNativeAD()
                        }.onAppear{
                            store.dispatch(.event(.vpnGuide))
                            store.dispatch(.rootUpdateLoadPostion(.vpnHome))
                            store.dispatch(.adLoad(.vpnHome, .vpnHome))
                            store.dispatch(.adLoad(.vpnConnect))
                        }
                    }
                    
                    // 进入 vpn 界面
                    if store.state.launched.pushVPNView {
                        NavigationLink(isActive: $store.state.launched.pushVPNView) {
                            VPNView().navigationTitle("VPN").navigationBarTitleDisplayMode(.inline).navigationBarBackButtonHidden().toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    if store.state.vpn.state == .connecting || store.state.vpn.state == .disconnecting {
                                        Image("back")
                                    } else {
                                        Button {
                                            if store.state.root.isUserGo {
                                                store.dispatch(.adLoad(.vpnBack))
                                                store.dispatch(.adShow(.vpnBack) { _ in
                                                    store.dispatch(.adDisappear(.vpnHome))
                                                    store.dispatch(.homeUpdatePushVPNView(false))
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                        clean(true)
                                                        store.dispatch(.event(.showCleanGuide))
                                                    }
                                                })
                                                store.dispatch(.event(.vpnBackAD))
                                            } else {
                                                store.dispatch(.adDisappear(.vpnHome))
                                                store.dispatch(.homeUpdatePushVPNView(false))
                                                clean(true)
                                                store.dispatch(.event(.showCleanGuide))
                                            }
                                            store.dispatch(.event(.vpnBack))
                                        } label: {
                                            Image("back")
                                        }
                                    }
                                }
                            }
                        } label: {
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

extension LaunchedView {
    func viewDidAppear() {
        if !isGuideShow, !isVPNVShow, !isTabShow{
            loadAndShowHomeNativeAD()
        }
        ATTrackingManager.requestTrackingAuthorization { _ in
        }
    }
    
    func loadAndShowHomeNativeAD() {
        store.dispatch(.rootUpdateLoadPostion(.native))
        store.dispatch(.adDisappear(.native))
        store.dispatch(.adLoad(.native, .home))
        store.dispatch(.event(.homeShow))
        store.dispatch(.event(.homeAD))
        if store.state.ad.isLoaded(.native) {
            store.dispatch(.event(.homeShowAD))
        }
    }
    
    func search() {
        store.dispatch(.hideKeyboard)
        if isLoading {
            store.dispatch(.stopLoad)
        } else {
            if text.count > 0 {
                store.dispatch(.loadURL(text))
                store.dispatch(.browser)
                store.dispatch(.event(.homeSearch, ["bro": text]))
            } else {
                alerMessage("Please enter your search content.")
            }
        }
    }
    
    func alerMessage(_ message: String) {
        SheetKit().present(with: .bottomSheet) {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Text(message)
            }.clearBackground()
        }
        Task{
            if !Task.isCancelled {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                SheetKit().dismiss()
            }
        }
    }
    
    func clean(_ isGuide: Bool = false){
        let configuration = SheetKit.BottomSheetConfiguration(  detents: [.large()], largestUndimmedDetentIdentifier: .large, prefersGrabberVisible: true, prefersScrollingExpandsWhenScrolledToEdge: false, prefersEdgeAttachedInCompactHeight: false, widthFollowsPreferredContentSizeWhenEdgeAttached: true, preferredCornerRadius: 10)
        SheetKit().present(with: .customBottomSheet, configuration: configuration) {
            CleanPopView(cleanHandle: {
                
                store.dispatch(.stopLoad)
                store.dispatch(.clean)
                store.dispatch(.browser)
                store.dispatch(.adDisappear(.native))
                store.state.launched.isCleanShow = true
                SheetKit().present(with: .fullScreenCover) {
                    CleanView() {
                        loadAD()
                        store.dispatch(.event(.cleanAnimationCompletion))
                        store.dispatch(.event(.cleanAlertShow))
                        self.alerMessage("Cleaned")
                        store.state.launched.isCleanShow = false
                    }.environmentObject(store)
                }
                if isGuide {
                    store.dispatch(.event(.cleanGuideOK))
                }
            }, dismissHandle: {
                if isGuide {
                    store.dispatch(.event(.cleanGuideSkip))
                }
            }).clearBackground()
        }
        store.dispatch(.event(.homeClean))
    }
    
    func searchIndex(_ index: AppState.LaunchedState.Index) {
        let url = index.url
        store.dispatch(.hideKeyboard)
        store.dispatch(.loadURL(url))
        store.dispatch(.browser)
        store.dispatch(.event(.homeClick, ["bro": index.rawValue]))
    }
    
    func tab() {
        store.state.launched.isTabShow = true
        store.dispatch(.adDisappear(.native))
        SheetKit().present(with: .fullScreenCover) {
            TableView(dismissHandle: {
                loadAD()
                store.state.launched.isTabShow = false
            }).environmentObject(store)
        }
    }
    
    func loadAD() {
        store.dispatch(.adLoad(.native, .home))
        store.dispatch(.adLoad(.interstitial))
    }
    
    func goBack() {
        store.state.browser.browser.goBack()
    }
    
    func goForword() {
        store.state.browser.browser.goForword()
    }
    
    func setting() {
        SheetKit().present(with: .bottomSheet) {
            SettingView(privacyHandle: {
                store.dispatch(.adDisappear(.native))
                SheetKit().present(with: .fullScreenCover) {
                    PrivacyView {
                        loadAD()
                    }
                }
            }, termsHandle: {
                store.dispatch(.adDisappear(.native))
                SheetKit().present(with: .fullScreenCover) {
                    TermsView {
                        loadAD()
                    }
                }
            }, shareHandle: {
                store.dispatch(.event(.shareClick))
                var url = ""
                if store.state.launched.isNavigation {
                    url = "https://itunes.apple.com/cn/app/id6450207177"
                } else {
                    url = store.state.launched.text
                }
                SheetKit().present {
                    ShareView(url: url)
                }
            }, copyHandle: {
                store.dispatch(.event(.copyClick))
                store.dispatch(.copy)
                self.alerMessage("Copied")
            }).clearBackground().environmentObject(store)
        }
    }
}

struct LaunchedView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchedView().environmentObject(AppStore())
    }
}
