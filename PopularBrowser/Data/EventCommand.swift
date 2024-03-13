//
//  EventCommand.swift
//  PopularBrowser
//
//  Created by hero on 7/3/2024.
//

import Foundation
import FBSDKCoreKit
import Adjust


struct NativeADEventCommand: AppCommand {
    enum Position {
        case vpnHome, vpnResult
    }
    let postion: Position
    init(postion: Position) {
        self.postion = postion
    }
    func execute(in store: AppStore) {
        if self.postion == .vpnHome {
            loadAndShowVPNHomeAD(in: store)
        } else {
            loadAndShowVPNResultAD(in: store)
        }
    }
    
    func loadAndShowVPNHomeAD(in store: AppStore) {
        store.dispatch(.event(.vpnHomeAD))
        
        store.dispatch(.rootUpdateLoadPostion(.vpnHome))
        store.dispatch(.adDisappear(.vpnHome))
        store.dispatch(.adLoad(.vpnHome, .vpnHome))
        
        
        if store.state.root.isUserGo {
            store.dispatch(.adLoad(.vpnBack))
        }
    }
    
    func loadAndShowVPNResultAD(in store: AppStore) {

    }
}

struct FBPurchaseEventCommand: AppCommand {
    let ad: ADBaseModel?
    init(_ ad: ADBaseModel?) {
        self.ad = ad
    }
    func execute(in store: AppStore) {
        if let price = ad?.price, let currency = ad?.currency {
            CacheUtil.shared.addFBPrice(price: price , currency: currency);
            debugPrint("[fb] price:\(price), currency:\(currency)")
            if CacheUtil.shared.needUploadFBPrice(), let price = CacheUtil.shared.fbPrice?.price {
                debugPrint("[fb] price:\(price), currency:\(currency)")
                FBSDKCoreKit.AppEvents.shared.logPurchase(amount: price, currency: currency)
                let adRevenue = ADJEvent(eventToken: "9e03lz")
                adRevenue?.setRevenue(price, currency: currency)
                Adjust.trackEvent(adRevenue)
            }
        }
    }
}
