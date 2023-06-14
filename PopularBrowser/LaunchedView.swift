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
    
    @State var isTabShow = false
    
    var body: some View {
        GeometryReader { _ in
            VStack{
                ProgressView(value: progress, total: 1.0).accentColor(Color("#FA44B2")).opacity(isLoading ? 1.0 : 0.0)
                HStack{
                    TextField("Seaech or enter address", text: $store.state.launched.text).padding(.vertical, 18).padding(.leading, 20)
                    Button(action: search) {
                        Image(isLoading ? "search_stop" : "search").padding(.trailing, 20)
                    }
                }.background(RoundedRectangle(cornerRadius: 28).stroke(Color("#8A8A8A"), lineWidth: 1)).padding(.horizontal, 24)
                VStack(spacing: 20){
                    if isNavigation {
                        Image("launch_icon").padding(.top, 60)
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
                        }.padding(.horizontal, 16).padding(.top, 40)
                    } else if !isTabShow {
                        WebView(webView: store.state.browser.browser.webView)
                    }
                }
                Spacer()
                HStack{
                    Button(action: goBack) {
                        Image(canGoBack ? "left" : "left_1")
                    }
                    Spacer()
                    Button(action: goForword) {
                        Image(canGoForword ? "right" : "right_1")
                    }
                    Spacer()
                    Button(action: clean) {
                        Image("clean")
                    }
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
        }
    }
}

extension LaunchedView {
    func viewDidAppear() {
        store.dispatch(.event(.homeShow))
        ATTrackingManager.requestTrackingAuthorization { _ in
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
    
    func clean(){
        let configuration = SheetKit.BottomSheetConfiguration(  detents: [.large()], largestUndimmedDetentIdentifier: .large, prefersGrabberVisible: true, prefersScrollingExpandsWhenScrolledToEdge: false, prefersEdgeAttachedInCompactHeight: false, widthFollowsPreferredContentSizeWhenEdgeAttached: true, preferredCornerRadius: 10)
        SheetKit().present(with: .customBottomSheet, configuration: configuration) {
            CleanPopView(dismissHandle: {
                
                store.dispatch(.stopLoad)
                store.dispatch(.clean)
                
                SheetKit().present(with: .fullScreenCover) {
                    CleanView {
                        store.dispatch(.event(.cleanAnimationCompletion))
                        store.dispatch(.event(.cleanAlertShow))
                        self.alerMessage("Cleaned")
                    }
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
        isTabShow = true
        SheetKit().present(with: .fullScreenCover) {
            TableView(dismissHandle: {
                isTabShow = false
            }).environmentObject(store)
        }
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
                SheetKit().present(with: .fullScreenCover) {
                    PrivacyView()
                }
            }, termsHandle: {
                SheetKit().present(with: .fullScreenCover) {
                    TermsView()
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
