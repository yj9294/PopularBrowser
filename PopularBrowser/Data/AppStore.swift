//
//  Store.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation
import Combine
import UIKit

class AppStore: ObservableObject {
    @Published var state = AppState()
    var publishers = [AnyCancellable]()
    init() {
        dispatch(.property(.local))
        dispatch(.event(.open))
        dispatch(.event(.openCold))
        UITabBar.appearance().isHidden = true
        dispatch(.remoteConfig)
        dispatch(.adLimitRefresh)
    }
    func dispatch(_ action: AppAction) {
        debugPrint("[ACTION]: \(action)")
        let result = AppStore.reduce(state: state, action: action)
        state = result.0
        if let command = result.1 {
            command.execute(in: self)
        }
    }
}


extension AppStore{
    private static func reduce(state: AppState, action: AppAction) -> (AppState, AppCommand?) {
        var appState = state
        var appCommand: AppCommand? = nil
        switch action {
        case .rootSelection(let index):
            if index == .launching {
                appState.root.progress = 0.0
            }
            appState.root.selection = index
        case .browser:
            appCommand = BrowserCommand()
        case .hideKeyboard:
            appCommand = HideKeyboardCommand()
        case .loadURL(let url):
            appState.launched.isLoading = true
            appState.launched.progress = 0.0
            appState.browser.browser.load(url)
        case .stopLoad:
            appState.launched.isLoading = false
            appState.launched.text = ""
            appState.browser.browser.stopLoad()
        case .select(let browser):
            appCommand = BrowserSelectItem(browser)
        case .delete(let browser):
            appCommand = BrowserDeleteItem(browser)
        case .add(let browser):
            appState.browser.browser.isSelect = false
            appState.browser.browsers.insert(browser, at: 0)
        case .copy:
            appCommand = CopyCommand()
        case .clean:
            appState.browser.browsers = [.navigation]
        case .event(let name, let value):
            appState.firebase.item.log(event: name, params: value)
        case .property(let name):
            appState.firebase.item.log(property: name)
            
        case .remoteConfig:
            appCommand = RemoteConfigCommand()
        case .adLimitRefresh:
            appCommand = GADLimitRefreshCommand()
        case .adUpdateConfig(let config):
            appState.ad.config = config
        case .adUpdateLimit(let state):
            appCommand = GADUpdateLimitCommand(state)
        case .adAppear(let position):
            appCommand = GADAppearCommand(position)
        case .adDisappear(let position):
            appCommand = GADDisappearCommand(position)
        case .adClean(let position):
            appCommand = GADCleanCommand(position)
        
        case .adLoad(let position, let p):
            appCommand = GADLoadCommand(position, p)
        case .adShow(let position, let p, let completion):
            appCommand = GADShowCommand(position, p, completion)
            
        case .adNativeImpressionDate(let p):
            appState.ad.impressionDate[p] = Date()
        case .adModel(let model):
            appState.root.adModel = model
        case .dismiss:
            appCommand = DismissCommand()
        }
        return (appState, appCommand)
    }
}
