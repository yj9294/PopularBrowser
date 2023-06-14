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
}

extension AppState {
    struct RootState {
        enum Index{
            case launching, launched
        }
        var selection: Index = .launching
    }
}

extension AppState {
    struct LaunchedState {
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
    struct FirebaseState {
        var item: FirebaseItem = .default
        enum Property: String {
            /// 設備
            case local = "lightBro_borth"
            
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
            
            case open = "lightBro_lun"
            case openCold = "lightBro_clod"
            case openHot = "lightBro_hot"
            case homeShow = "lightBro_impress"
            case homeClick = "lightBro_nav"
            case homeSearch = "lightBro_search"
            case homeClean = "lightBro_clean"
            case cleanAnimationCompletion = "lightBro_cleanDone"
            case cleanAlertShow = "lightBro_cleanToast"
            case tabShow = "lightBro_showTab"
            case webNew = "lightBro_clickTab"
            case shareClick = "lightBro_share"
            case copyClick = "lightBro_copy"
            case searchBegian = "lightBro_requist"
            case searchSuccess = "lightBro_load"
        }
    }
}
