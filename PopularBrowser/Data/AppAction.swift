//
//  AppAction.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation

enum AppAction {
    case rootSelection(AppState.RootState.Index)
    case rootUpdateIPError(Bool)
    case rootUpdateBackground(Bool)
    case rootUpdateTime(Int)
    case rootUpdateColdVPN(Bool)
    case rootUpdateUserGo(Bool)
    case rootUpdateIP(String)
        
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
    case updateVPNCountry(CountryModel.Country?)
    case updateVPNCountryList(CountryModel?)
    case updateAlertMessage(String)
    case dismissAlert
    case vpnUpdatePushResult(Bool)
    case vpnUpdateConnectedDate(Date)
    case vpnUpdatePushServerView(Bool)
    
    case updateVPNMutaConnect(Bool)
    case updateVPNMutaDisconnect(Bool)
    case updateVPNAutoConnect(Bool)
    
    case resultUpdate(Bool)
    
    case dismiss
    
    case adjustInit
    
    case updateVPNADModel(NativeViewModel)
    case updateVPNResultADModel(NativeViewModel)
    
    case rootUpdateLoadPostion(GADPosition)
    
    case requestCloak
    case requestIP
    case requestServer
    
    case loadVPNResultAD
    
    // tab
    case tbaInstall
    case tbaSession
    case tbaAd(ADBaseModel?)
    case fbPurchase(ADBaseModel?)
    case tbaFirstOpen
}
