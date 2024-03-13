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
        dispatch(.rootSelection(.launching))
        
        // 冷启动都弹出引导
        dispatch(.homeUpdateShowGuide(true))
        
        // vpn 初始化
        dispatch(.vpnInit)
        
        // adjust 初始化
        dispatch(.adjustInit)
        
        // 冷启动
        dispatch(.rootUpdateColdVPN(true))
        
        // tba install 事件
        dispatch(.tbaInstall)
        dispatch(.tbaSession)
        
        // tba first open 事件
        dispatch(.tbaFirstOpen)
        
        // 请求 server
        dispatch(.requestServer)
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
        case .adjustInit:
            appCommand = ADjustInitCommand()
        case .rootUpdateTime(let time):
            appState.root.time = time
        case .requestIP:
            appCommand = RequestIPCommand()
        case .requestServer:
            appCommand = RequestServersCommand()
        case .rootSelection(let index):
            if index == .launching {
                appCommand = LaunchCommand()
            }
            appState.root.selection = index
        case .rootUpdateIPError(let isShow):
            appState.root.showCNError = isShow
            if !isShow {
                exit(0)
            }
        case .rootUpdateBackground(let background):
            appState.root.enterbackground = background
            if background {
                appCommand = BackgroundCommand()
            }
        case .rootUpdateColdVPN(let cold):
            appState.root.coldVPN = cold
        case .rootUpdateUserGo(let go):
            appState.root.userGo = go
            
        case .homeUpdateShowGuide(let isShow):
            appState.launched.showGuide = isShow
        case .homeUpdatePushVPNView(let isPush):
            appState.launched.pushVPNView = isPush
            if isPush {
                appCommand = NativeADEventCommand(postion: .vpnHome)
            }
            
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
            appCommand = RequestEventCommand(name: name.rawValue, value: value)
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
            
        case .vpnInit:
            appCommand = VPNInitCommand()
        case .vpnConnect:
            appCommand = VPNConnectCommand()
        case .vpnDisconnect:
            appCommand = VPNConnectCommand(true)
        case .updateVPNPermission(let isAlert):
            appState.vpn.permissonAlert = isAlert
        case .updateVPNStatus(let status):
            appState.vpn.state = status
            if status == .error {
                appState.vpn.alertMessage = "Try it agin."
                appState.vpn.isAlert = true
            }
            if status == .connected {
                appState.vpn.isAutoConnect = false
                appCommand = VPNResultConnectCommand()
            }
            if status == .disconnecting {
                appCommand = ConnectingSceneCommand()
            }
            if status  == .connecting {
                appCommand = ConnectingSceneCommand()
            }
            if status == .disconnected, appState.vpn.isMutaDisconnect {
                appCommand = VPNResultDisconnectCommand()
            } else if status == .disconnected, appState.vpn.isAutoConnect {
                appCommand = VPNConnectCommand()
            }
        case .updateVPNCountry(let country):
            appState.vpn.country = country
        case .updateAlertMessage(let message):
            appState.vpn.alertMessage = message
            appState.vpn.isAlert = true
        case .dismissAlert:
            appState.vpn.isAlert = false
        case .vpnUpdatePushResult(let isPush):
            appState.vpn.isPushResult = isPush
        case .vpnUpdatePushServerView(let isPush):
            appState.vpn.isPushServerList = isPush
            
        case .updateVPNMutaConnect(let isMutaConnect):
            appState.vpn.isMutaConnect = isMutaConnect
        case .updateVPNMutaDisconnect(let isMutaConnect):
            appState.vpn.isMutaDisconnect = isMutaConnect
        case .updateVPNAutoConnect(let isAuto):
            appState.vpn.isAutoConnect = isAuto
        case .vpnUpdateConnectedDate(let date):
            appState.vpn.date = date
        case .updateVPNCountryList(let list):
            appState.vpn.servers = list
            if let list = list {
                appState.vpn.servers?.hCountries = CountryModel.repeatCountry(with: list.hCountries)
                appState.vpn.servers?.lCountries = CountryModel.repeatCountry(with: list.lCountries)
            }
             
            
        case .resultUpdate(let isConnected):
            appState.result.isConnected = isConnected
            
        case .updateVPNADModel(let model):
            appState.vpn.ad = model
        case .updateVPNResultADModel(let model):
            appState.result.ad = model
        case .rootUpdateLoadPostion(let position):
            appState.root.nativeLoadPosition = position
            
        case .requestCloak:
            appCommand = RequestClakCOmmand()
            
        case .loadVPNResultAD:
            appCommand = NativeADEventCommand(postion: .vpnResult)
        case .tbaInstall:
            appCommand = RequestInstallEventCommand()
        case .tbaSession:
            appCommand = RequestSessionEventCommand()
        case .tbaAd(let model):
            appCommand = RequestADEventCommand(model)
        case .fbPurchase(let model):
            appCommand = FBPurchaseEventCommand(model)
        case .tbaFirstOpen:
            appCommand = RequestFirstOpenEventCommand()
        }
        return (appState, appCommand)
    }
}
