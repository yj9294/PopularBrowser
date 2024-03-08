//
//  State.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation

struct AppState {
    var root = RootState()
    var launched = LaunchedState()
    var browser = BrowserState()
    var firebase = FirebaseState()
    var ad = ADState()
    var vpn = VPNState()
    var result = ResultState()
}

extension AppState {
    struct RootState {
        // 判定 中国 IP 弹窗
        var showCNError: Bool = false
        
        // cloak 激进模式
        @UserDefault(key: "user.go")
        var userGo: Bool?
        var isUserGo: Bool {
            userGo ?? false
        }
        
        // 进入后台用于阻塞连接vpn操作
        var enterbackground = false
        
        var adModel: NativeViewModel = .None
        enum Index{
            case launching, launched
        }
        var selection: Index = .launching
        var progress: Double = 0.0
        var duration: Double = 13.0
        
        // 倒计时 10分钟关闭vpn
        var time: Int = -1
        
        // 冷启动进入vpn界面
        @UserDefault(key: "cold.vpn")
        var coldVPN: Bool?
        
        // 用于判定原生广告加载完成时在那个界面
        var nativeLoadPosition: GADPosition = .native
    }
}

extension AppState {
    struct LaunchedState {
        
        var isTabShow: Bool = false
        var isCleanShow: Bool = false
        
        // 引导标识
        @UserDefault(key: "guide")
        var showGuide: Bool?
        var isShowGuide: Bool {
            showGuide ?? true
        }
        
        // 进入 vpn 界面
        var pushVPNView: Bool = false
        
        var text: String = ""
        var isLoading: Bool = false
        var canGoBack: Bool = false
        var canGoForword: Bool = false
        var isNavigation: Bool = true
        var progress: Double = 0.0
        enum Index: String, CaseIterable {
            case youtube, facebook, google, twitter, gmail, instagram, amazon, yahoo
            var title: String {
                return "\(self)".capitalized
            }
            var url: String {
                return "https://www.\(self).com"
            }
            var icon: String {
                return "\(self)"
            }
        }
    }
}

extension AppState {
    struct BrowserState {
        var browsers: [Browser] = [.navigation]
        var browser: Browser {
            browsers.filter {
                $0.isSelect
            }.first ?? .navigation
        }
    }
}

extension AppState {
    struct ADState {
        @UserDefault(key: "state.config")
        var config: GADConfig?
       
        @UserDefault(key: "state.limit")
        var limit: GADLimit?
        
        var impressionDate:[GADPosition.Position: Date] = [:]
        
        let ads:[ADLoadModel] = GADPosition.allCases.map { p in
            ADLoadModel(position: p)
        }
        
        func isLoaded(_ position: GADPosition) -> Bool {
            return self.ads.filter {
                $0.position == position
            }.first?.isLoaded == true
        }

        func isLimited(in store: AppStore) -> Bool {
            if limit?.date.isToday == true {
                if (store.state.ad.limit?.showTimes ?? 0) >= (store.state.ad.config?.showTimes ?? 0) || (store.state.ad.limit?.clickTimes ?? 0) >= (store.state.ad.config?.clickTimes ?? 0) {
                    return true
                }
            }
            return false
        }
    }
}

extension AppState {
    
    struct VPNState {
        
        var ad: NativeViewModel = .BigNone
        
        // vpn 状态
        var state: VPNUtil.VPNState = .idle
    
        @UserDefault(key: "vpn.country.list")
        var countryList: [VPNCountryModel]?
        // VPN 连接国家
        @UserDefault(key: "vpn.country")
        var country: VPNCountryModel?
        var serverTitle: String {
            country?.title ?? "Smart Server "
        }
        
        // vpn 权限弹窗标识
        @UserDefault(key: "vpn.permission")
        var permissonAlert: Bool?
        var isPermissonAlert: Bool {
            return permissonAlert ?? false
        }
        
        // 提示
        var alertMessage: String = ""
        var isAlert: Bool = false
        
        // push result
        var isPushResult: Bool = false
        
        // 手动连接
        var isMutaConnect = false
        var isMutaDisconnect = false
        
        // 链接时长
        var date = Date()
    }
}

extension AppState {
    struct ResultState {
        var isConnected = true
        
        var ad: NativeViewModel = .BigNone
    }
}

extension AppState {
    struct FirebaseState {
        var item: FirebaseItem = .default
        enum Property: String {
            /// 設備
            case local = "pobr_borth"
            
            var first: Bool {
                switch self {
                case .local:
                    return true
                }
            }
        }
        
        enum Event: String {
            
            var first: Bool {
                switch self {
                case .open:
                    return true
                default:
                    return false
                }
            }
            
            case open = "pobr_lun"
            case openCold = "pobr_clod"
            case openHot = "pobr_hot"
            case homeShow = "pobr_impress"
            case homeClick = "pobr_nav"
            case homeSearch = "pobr_search"
            case homeClean = "pobr_clean"
            case cleanAnimationCompletion = "pobr_cleanDone"
            case cleanAlertShow = "pobr_cleanToast"
            case tabShow = "pobr_showTab"
            case webNew = "pobr_clickTab"
            case shareClick = "pobr_share"
            case copyClick = "pobr_copy"
            case searchBegian = "pobr_requist"
            case searchSuccess = "pobr_load"
            
            case coldVPN = "pobr_1"
            case vpnBack = "pobr_homeback"
            case vpnConnect = "pobr_link"
            case vpnConnected = "pobr_link2"
            case vpnConnect1 = "pobr_link0"
            case vpnPermission = "pobr_pm"
            case vpnPermissionAgree = "pobr_pm2"
            case vpnResultConnected = "pobr_re1"
            case vpnResultDisconnected = "pobr_re2"
            case vpnConnectedDate = "pobr_disLink"
            case vpnGuide = "pobr_pop"
            case vpnGuideSkip = "pobr_pop0"
            case vpnGuideOK = "pobr_pop1"
            
            case loadingAD = "pobr_enter_1"
            case homeAD = "pobr_enter_2"
            case cleanAD = "pobr_enter_3"
            case tabAD = "pobr_enter_4"
            case vpnHomeAD = "pobr_enter_5"
            case vpnConnectAD = "pobr_enter_6"
            case vpnDisconnectAD = "pobr_enter_7"
            case connectResultAD = "pobr_enter_8"
            case disconnectResultAD = "pobr_enter_9"
            case vpnBackAD = "pobr_enter_10"
            
            case loadingShowAD = "pobr_start_1"
            case homeShowAD = "pobr_start_2"
            case cleanShowAD = "pobr_start_3"
            case tabShowAD = "pobr_start_4"
            case vpnHomeShowAD = "pobr_start_5"
            case vpnConnectShowAD = "pobr_start_6"
            case vpnDisconnectShowAD = "pobr_start_7"
            case connectResultShowAD = "pobr_start_8"
            case disconnectResultShowAD = "pobr_start_9"
            case vpnBackShowAD = "pobr_start_10"
            
            case loadingImpressAD = "pobr_success_1"
            case homeImpressAD = "pobr_success_2"
            case cleanImpressAD = "pobr_success_3"
            case tabImpresssAD = "pobr_success_4"
            case vpnHomeImpressAD = "pobr_success_5"
            case vpnConnectImpressAD = "pobr_success_6"
            case vpnDisconnectImpressAD = "pobr_success_7"
            case connectResultImpressAD = "pobr_success_8"
            case disconnectResultImpressAD = "pobr_success_9"
            case vpnBackImpressAD = "pobr_success_10"
        }
    }
}
