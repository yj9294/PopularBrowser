//
//  VPNView.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import SwiftUI

struct VPNView: View {
    var body: some View {
        VStack{
            Button {
                connect()
            } label: {
                Text("connect")
            }
        }.onAppear{
            viewDidAppear()
        }
    }
}

extension VPNView {
    
    func viewDidAppear() {
        
    }
    
    func connect() {
        if VPNUtil.shared.managerState == .idle || VPNUtil.shared.managerState == .error {
            VPNUtil.shared.create { err in
                if let err = err {
                    debugPrint("[CONNECT] err:\(err.localizedDescription)")
                    return
                }
                doConnect(model: VPNCountryModel.smartModel)
            }
        } else {
            doConnect(model: VPNCountryModel.smartModel)
        }
    }
    
    // 选择好了线路，开始链接中
    func doConnect(model: VPNCountryModel?) {
        guard let model = model else {
            debugPrint("[CONNECT] no selectServer")
            return
        }
        let host = model.ip
        let port = model.port
        let method = "chacha20-ietf-poly1305"
        let op = ["host": host,"port": port,"method": method,"password": model.password] as? [String : NSObject]
        VPNUtil.shared.connect(options: op)
    }
}
