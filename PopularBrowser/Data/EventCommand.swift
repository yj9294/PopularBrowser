//
//  EventCommand.swift
//  PopularBrowser
//
//  Created by hero on 7/3/2024.
//

import Foundation

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
