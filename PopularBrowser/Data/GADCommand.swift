//
//  GADCommand.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/14.
//

import Foundation
import GoogleMobileAds
import Firebase

struct GADLimitRefreshCommand: AppCommand {
    func execute(in store: AppStore) {
        /// 广告配置是否是当天的
        if store.state.ad.limit == nil || store.state.ad.limit?.date.isToday != true {
            store.state.ad.limit = GADLimit(showTimes: 0, clickTimes: 0, date: Date())
        }
    }
}

struct GADUpdateLimitCommand: AppCommand {
    
    let status: GADLimit.Status
    
    init(_ status: GADLimit.Status) {
        self.status = status
    }
    
    func execute(in store: AppStore) {
        if store.state.ad.isLimited(in: store) {
            NSLog("[AD] 用戶超限制。")
            store.dispatch(.adClean(.interstitial))
            store.dispatch(.adClean(.native))
            store.dispatch(.adDisappear(.native))
            return
        }

        if status == .show {
            let showTime = store.state.ad.limit?.showTimes ?? 0
            store.state.ad.limit?.showTimes = showTime + 1
            NSLog("[AD] [LIMIT] showTime: \(showTime+1) total: \(store.state.ad.config?.showTimes ?? 0)")
        } else  if status == .click {
            let clickTime = store.state.ad.limit?.clickTimes ?? 0
            store.state.ad.limit?.clickTimes = clickTime + 1
            NSLog("[AD] [LIMIT] clickTime: \(clickTime+1) total: \(store.state.ad.config?.clickTimes ?? 0)")
        }
    }
    
}

struct GADAppearCommand: AppCommand {
    let postion: GADPosition
    
    init(_ postion: GADPosition) {
        self.postion = postion
    }
    
    func execute(in store: AppStore) {
        store.state.ad.ads.filter {
            $0.position == postion
        }.first?.display()
    }
}

struct GADDisappearCommand: AppCommand {
    let position: GADPosition
    
    init(_ position: GADPosition) {
        self.position = position
    }
    
    func execute(in store: AppStore) {
        store.state.ad.ads.filter{
            $0.position == position
        }.first?.closeDisplay()
        
        if position == .native {
            store.dispatch(.adModel(.None))
        } else if position == .vpnHome {
            store.dispatch(.updateVPNADModel(.BigNone))
        } else if position == .vpnResult {
            store.dispatch(.updateVPNResultADModel(.BigNone))
        }
    }
}

struct GADCleanCommand: AppCommand {
    let position: GADPosition
    
    init(_ position: GADPosition) {
        self.position = position
    }
    
    func execute(in store: AppStore) {
        let loadAD = store.state.ad.ads.filter{
            $0.position == position
        }.first
        loadAD?.clean()
    }
}

struct GADLoadCommand: AppCommand {
    
    let position: GADPosition
    
    let p: GADPosition.Position
    
    var completion: ((NativeViewModel)->Void)? = nil
    
    init(_ position: GADPosition, _ p: GADPosition.Position, _ completion: ((NativeViewModel)->Void)? = nil) {
        self.position = position
        self.p = p
        self.completion = completion
    }
    
    func execute(in store: AppStore) {
        let ads = store.state.ad.ads.filter{
            $0.position == position
        }
        if let ad = ads.first {
            // 插屏直接一步加载
            if position.isInterstitial {
                ad.beginAddWaterFall(callback: { isSuccess in
                    self.completion?(.None)
                }, in: store)
            } else if position.isNative{
                // 原生广告需要同步显示
                ad.beginAddWaterFall(callback: { isSuccess in
                    if isSuccess {
                        store.dispatch(.adShow(self.position, self.p, completion))
                    }
                }, in: store)
            }
        } else {
            debugPrint("[AD] \(position) no config.")
        }
    }
}

struct GADShowCommand: AppCommand {
    let position: GADPosition
    let p: GADPosition.Position
    var completion: ((NativeViewModel)->Void)? = nil
    
    init(_ position: GADPosition, _ p: GADPosition.Position = .home, _ completion: ((NativeViewModel)->Void)? = nil) {
        self.position = position
        self.p = p
        self.completion = completion
    }
    
    func execute(in store: AppStore) {
        
        // 超限需要清空广告
        if store.state.ad.isLimited(in: store) {
            store.dispatch(.adClean(.interstitial))
            store.dispatch(.adClean(.native))
            store.dispatch(.adDisappear(.native))
        }
        let loadAD = store.state.ad.ads.filter {
            $0.position == position
        }.first
        
        if position.isInterstitial {
            /// 有廣告
            if let ad = loadAD?.loadedArray.first as? InterstitialADModel, !store.state.ad.isLimited(in: store) {
                ad.interstitialAd?.paidEventHandler = { [weak ad] adValue in
                    ad?.network = ad?.interstitialAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName ?? ""
                    ad?.price = Double(truncating: adValue.value)
                    ad?.currency = adValue.currencyCode
                    store.dispatch(.tbaAd(ad))
                    store.dispatch(.fbPurchase(ad))
                }
                ad.impressionHandler = {
                    logEvent(position, in: store)
                    store.dispatch(.adUpdateLimit(.show))
                    store.dispatch(.adAppear(position))
                    if position != .vpnBack || position != .vpnHome {
                        store.dispatch(.adLoad(position))
                    }
                }
                ad.clickHandler = {
                    if !store.state.ad.isLimited(in: store) {
                        store.dispatch(.adUpdateLimit(.click))
                        if store.state.ad.isLimited(in: store) {
                            NSLog("[ad] 广告超限 点击无效")
                        }
                    } else {
                        NSLog("[ad] 广告超限 点击无效")
                    }
                }
                ad.closeHandler = {
                    completion?(.None)
                    store.dispatch(.adDisappear(position))
                }
                logShowEvent(ad.position, in: store)
                ad.present()
            } else {
                completion?(.None)
            }
        } else if position.isNative {
            if let ad = loadAD?.loadedArray.first as? NativeADModel, !store.state.ad.isLimited(in: store) {
                /// 预加载回来数据 当时已经有显示数据了
                if loadAD?.isDisplay == true {
                    return
                }
                ad.nativeAd?.unregisterAdView()
                ad.nativeAd?.delegate = ad
                ad.nativeAd?.paidEventHandler = { [weak ad] adValue in
                    ad?.network = ad?.nativeAd?.responseInfo.loadedAdNetworkResponseInfo?.adNetworkClassName ?? ""
                    ad?.price = Double(truncating: adValue.value)
                    ad?.currency = adValue.currencyCode
                    store.dispatch(.tbaAd(ad))
                    store.dispatch(.fbPurchase(ad))
                }
                ad.impressionHandler = {
                    logEvent(position, in: store)
                    store.dispatch(.adNativeImpressionDate(p))
                    store.dispatch(.adUpdateLimit(.show))
                    store.dispatch(.adAppear(position))
                    if position != .vpnHome {
                        store.dispatch(.adLoad(position, p))
                    }
                }
                ad.clickHandler = {
                    store.dispatch(.adUpdateLimit(.click))
                }
                // 10秒间隔
                if let date = store.state.ad.impressionDate[p], Date().timeIntervalSince1970 - date.timeIntervalSince1970  < 10 {
                    NSLog("[ad] 刷新或数据加载间隔 10s postion: \(p)")
                    store.dispatch(.adModel(.None))
                    store.dispatch(.updateVPNADModel(.BigNone))
                    store.dispatch(.updateVPNResultADModel(.BigNone))
                    completion?(.None)
                    NotificationCenter.default.post(name: .nativeAdLoadCompletion, object: NativeViewModel.None)
                    return
                }
                
                var style: UINativeAdView.Style = .small
                if position == .vpnResult || position == .vpnHome {
                    style = .big
                }
                let adViewModel = NativeViewModel(ad:ad, view: UINativeAdView(style))
                completion?(adViewModel)
                /// 异步加载 回调是nil的情况使用通知
                NotificationCenter.default.post(name: .nativeAdLoadCompletion, object: adViewModel)
                if position == .vpnHome, store.state.launched.pushVPNView, !store.state.vpn.isPushResult {
                    store.dispatch(.event(.vpnHomeShowAD))
                }
            } else {
                /// 预加载回来数据 当时已经有显示数据了 并且没超过限制
                if loadAD?.isDisplay == true, !store.state.ad.isLimited(in: store) {
                    return
                }
                completion?(.None)
                store.dispatch(.adModel(.None))
                store.dispatch(.updateVPNADModel(.BigNone))
                store.dispatch(.updateVPNResultADModel(.BigNone))
            }
        }
    }
    
    func logShowEvent(_ position: GADPosition, in store: AppStore) {
        switch position {
        case .interstitial:
            if store.state.launched.isCleanShow {
                store.dispatch(.event(.cleanShowAD))
            } else {
                store.dispatch(.event(.loadingShowAD))
            }
        case .vpnConnect:
            if store.state.vpn.state == .connected {
                store.dispatch(.event(.vpnConnectShowAD))
            } else if store.state.vpn.state == .disconnected {
                store.dispatch(.event(.vpnDisconnectShowAD))
            }
        case .vpnBack:
            store.dispatch(.event(.vpnBackShowAD))
        default:
            break
        }
    }
    
    
    func logEvent(_ position: GADPosition, in store: AppStore) {
        switch position {
        case .native:
            if store.state.launched.isTabShow {
                store.dispatch(.event(.tabImpresssAD))
            } else {
                store.dispatch(.event(.homeImpressAD))
            }
        case .interstitial:
            if store.state.launched.isCleanShow {
                store.dispatch(.event(.cleanImpressAD))
            } else {
                store.dispatch(.event(.loadingImpressAD))
            }
        case .vpnHome:
            store.dispatch(.event(.vpnHomeImpressAD))
        case .vpnResult:
            if store.state.result.isConnected {
                store.dispatch(.event(.connectResultImpressAD))
            } else {
                store.dispatch(.event(.disconnectResultImpressAD))
            }
        case .vpnConnect:
            if store.state.vpn.state == .connected {
                store.dispatch(.event(.vpnConnectImpressAD))
            } else if store.state.vpn.state == .disconnected{
                store.dispatch(.event(.vpnDisconnectImpressAD))
            }
        case .vpnBack:
            store.dispatch(.event(.vpnBackImpressAD))
        }
    }
}

extension Notification.Name {
    static let nativeAdLoadCompletion = Notification.Name(rawValue: "nativeAdLoadCompletion")
}
