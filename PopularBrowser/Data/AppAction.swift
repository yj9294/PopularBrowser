//
//  AppAction.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation

enum AppAction {
    case rootRequestIP
    case rootSelection(AppState.RootState.Index)
    case rootUpdateIPError(Bool)
    case rootUpdateBackground(Bool)
    case rootUpdateTime(Int)
    case rootUpdateColdVPN(Bool)
    
    case homeUpdateShowGuide(Bool)
    case homeUpdatePushVPNView(Bool)
    case browser
    case hideKeyboard
    case loadURL(String)
    case stopLoad
    case delete(Browser)
    case select(Browser)
    case add(Browser)
    case copy
    case clean
    
    case event(AppState.FirebaseState.Event, [String: String]? = nil)
    case property(AppState.FirebaseState.Property)
    
    case remoteConfig
    case adLimitRefresh
    case adUpdateConfig(GADConfig)
    case adUpdateLimit(GADLimit.Status)
    case adAppear(GADPosition)
    case adDisappear(GADPosition)
    case adClean(GADPosition)
    case adLoad(GADPosition, GADPosition.Position = .home)
    case adShow(GADPosition, GADPosition.Position = .home, ((NativeViewModel)->Void)? = nil)
    case adNativeImpressionDate(GADPosition.Position = .home)
    case adModel(NativeViewModel)
    
    case vpnInit
    case vpnConnect
    case vpnDisconnect
    case updateVPNPermission(Bool)
    case updateVPNStatus(VPNUtil.VPNState)
    case updateVPNCountry(VPNCountryModel?)
    case updateAlertMessage(String)
    case dismissAlert
    case vpnUpdatePushResult(Bool)
    case vpnUpdateConnectedDate(Date)
    
    case updateVPNMutaConnect(Bool)
    case updateVPNMutaDisconnect(Bool)
    
    case resultUpdate(Bool)
    
    case dismiss
    
}
