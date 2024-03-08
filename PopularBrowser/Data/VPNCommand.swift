//
//  VPNCommand.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import Foundation
import Reachability
import BackgroundTasks
import Adjust

struct VPNInitCommand: AppCommand {
    func execute(in store: AppStore) {
        VPNUtil.shared.addStateObserver(VPNObserver(in: store))
        VPNUtil.shared.prepareForLoading {
            switch VPNUtil.shared.managerState {
            case .ready:
                store.dispatch(.updateVPNStatus(VPNUtil.shared.vpnState))
            default:
                break
            }
            debugPrint("[VPN MANAGER] prepareForLoading manager state: \(VPNUtil.shared.managerState), VPN state: \(VPNUtil.shared.vpnState)")
        }
    }
    
    func handleBackgroundTask(task: BGAppRefreshTask) {
        // 执行长时间后台任务逻辑
        print("Background Task Fired")
        // 任务完成时设置任务状态
        task.setTaskCompleted(success: true)
    }
}

struct ADjustInitCommand: AppCommand {
    func execute(in store: AppStore) {
        let config = ADJConfig(appToken: "q3xdvchy2t4w", environment: ADJEnvironmentProduction)
        config?.delayStart = 5.5
        Adjust.addSessionPartnerParameter("customer_user_id", value: CacheUtil.shared.getUUID())
        Adjust.appDidLaunch(config)
    }
} 

class VPNObserver: NSObject, VPNStateChangedObserver {
    func onStateChangedTo(state: VPNUtil.VPNState) {
        store.dispatch(.updateVPNStatus(state))
    }
    
    init(in store: AppStore) {
        self.store = store
    }
    var store: AppStore
}

struct VPNConnectCommand: AppCommand {
    let isDisconnect: Bool
    init(_ isDisconnect: Bool = false ) {
        self.isDisconnect = isDisconnect
    }
    func execute(in store: AppStore) {
        if !isDisconnect {
            connect(in: store)
        } else {
            disconnect(in: store)
        }
    }
    
    func connect(in store: AppStore) {
        store.dispatch(.updateVPNStatus(.connecting))
        if VPNUtil.shared.managerState == .idle || VPNUtil.shared.managerState == .error {
            store.dispatch(.updateVPNPermission(true))
            store.dispatch(.event(.vpnPermission))
            VPNUtil.shared.create { err in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    store.dispatch(.updateVPNPermission(false))
                }
                if let err = err {
                    store.dispatch(.updateVPNStatus(.disconnected))
                    debugPrint("[CONNECT] err:\(err.localizedDescription)")
                    return
                }
                store.dispatch(.event(.vpnPermissionAgree))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    pingServer(in: store)
                }
            }
        } else {
            pingServer(in: store)
        }
    }
    
    func pingServer(in store: AppStore) {
        // 网络判定
        if !connectNetwork(in: store) {
            store.dispatch(.updateVPNStatus(.disconnected))
            return
        }
        
        store.dispatch(.event(.vpnConnect))
        
        pingAllServers(serverList: store.state.vpn.countryList ?? []) { models in
            if let models = models, !models.isEmpty {
                // 找出 smart
                let model = VPNCountryModel.smartModel(with: models)
                store.dispatch(.updateVPNCountry(model))
                
                // 是否进入后台
                if store.state.root.enterbackground {
                    store.dispatch(.updateVPNStatus(.disconnected))
                    return
                }
                doConnect(model: model, in: store)
            } else {
                store.dispatch(.updateAlertMessage("Try it agin."))
                store.dispatch(.updateVPNStatus(.disconnected))
            }
        }
    }
    
    func pingAllServers(serverList: [VPNCountryModel], completion: (([VPNCountryModel]?) -> Void)?) {
        var pingResult = [Int : [Double]]()
        if serverList.count == 0 {
            completion?(nil)
            return
        }
        var pingUtilDict = [Int : VPNPingUtil?]()


        let group = DispatchGroup()
        let queue = DispatchQueue.main
        for (index, server) in serverList.enumerated() {
            if server.ip.count == 0 {
                continue
            }
            group.enter()
            queue.async {
                pingUtilDict[index] = VPNPingUtil.startPing(hostName: server.ip, count: 1, pingCallback: { pingItem in
                    switch pingItem.status! {
                        case .start:
                            pingResult[index] = []
                            break
                        case .failToSendPacket:
                            group.leave()
                            break
                        case .receivePacket:
                            pingResult[index]?.append(pingItem.singleTime!)
                        case .receiveUnpectedPacket:
                            break
                        case .timeout:
                            pingResult[index]?.append(1000.0)
                            group.leave()
                        case .error:
                            group.leave()
                        case .finished:
                            pingUtilDict[index] = nil
                            group.leave()
                    }
                })
            }
        }
        group.notify(queue: DispatchQueue.main) {
            var pingAvgResult = [Int : Double]()
            pingResult.forEach {
                if $0.value.count > 0 {
                    let sum = $0.value.reduce(0, +)
                    let avg = Double(sum) / Double($0.value.count)
                    pingAvgResult[$0.key] = avg
                }
            }

            if pingAvgResult.count == 0 {
                NSLog("[ERROR] ping error")
                completion?(nil)
                return
            }

            var serverList = serverList

            pingAvgResult.forEach {
                serverList[$0.key].delay = $0.value
            }

            serverList = serverList.filter {
                return ($0.delay ?? 0) > 0
            }

            serverList = serverList.sorted(by: { return ($0.delay ?? 0) < ($1.delay ?? 0) })

            serverList.forEach {
                debugPrint("[IP] \($0.country)-\($0.city)-\($0.ip)-\(String(format: "%.2f", $0.delay ?? 0 ))ms")
            }

            completion?(serverList)
        }
    }
    
    func connectNetwork(in store: AppStore) -> Bool {
        let reachability = try! Reachability()

        if reachability.connection == .unavailable {
            store.dispatch(.updateAlertMessage("Local network is not turned on."))
            return false
        } else {
            return true
        }
    }
    
    // 选择好了线路，开始链接中
    func doConnect(model: VPNCountryModel?, in store: AppStore) {
        guard let model = model else {
            debugPrint("[CONNECT] no selectServer")
            return
        }
        let host = model.ip
        let port = model.port
        let method = "chacha20-ietf-poly1305"
        let op = ["host": host,"port": port,"method": method,"password": model.password] as? [String : NSObject]
        VPNUtil.shared.connect(options: op)
        store.dispatch(.event(.vpnConnect1))
    }
    
    func disconnect(in store: AppStore) {
        store.dispatch(.updateVPNStatus(.disconnecting))
        VPNUtil.shared.stopVPN()
    }
}

struct VPNResultConnectCommand: AppCommand {
    
    func execute(in store: AppStore) {
        if store.state.vpn.isMutaConnect {
            store.dispatch(.updateVPNMutaConnect(false))
            store.dispatch(.updateVPNMutaDisconnect(false))
            
            store.dispatch(.event(.vpnConnectAD))
            store.dispatch(.adLoad(.vpnConnect))
            store.dispatch(.adShow(.vpnConnect) {_ in
                store.dispatch(.resultUpdate(true))
                store.dispatch(.vpnUpdatePushResult(true))
                loadResultNativeAD(in: store)
            })

            store.dispatch(.vpnUpdateConnectedDate(Date()))
            store.dispatch(.event(.vpnConnected, ["rot": store.state.vpn.country?.ip ?? ""]))
            store.dispatch(.event(.vpnResultConnected))
        }
    }
    
    
    func loadResultNativeAD(in store: AppStore) {
        if store.state.vpn.state == .connected {
            store.dispatch(.event(.connectResultAD))
            if store.state.ad.isLoaded(.vpnResult) {
                store.dispatch(.event(.connectResultShowAD))
            }
        } else if store.state.vpn.state == .disconnected {
            store.dispatch(.event(.disconnectResultAD))
            if store.state.ad.isLoaded(.vpnResult) {
                store.dispatch(.event(.disconnectResultShowAD))
            }
        }
        
        store.dispatch(.rootUpdateLoadPostion(.vpnResult))
        store.dispatch(.adDisappear(.vpnResult))
        store.dispatch(.adLoad(.vpnResult, .vpnResult))
    }
}

struct VPNResultDisconnectCommand: AppCommand {
    
    func execute(in store: AppStore) {
        if store.state.vpn.isMutaDisconnect {
            store.dispatch(.updateVPNMutaConnect(false))
            store.dispatch(.updateVPNMutaDisconnect(false))
            
            store.dispatch(.event(.vpnDisconnectAD))
            store.dispatch(.adLoad(.vpnConnect))
            store.dispatch(.adShow(.vpnConnect) {_ in
                store.dispatch(.resultUpdate(false))
                store.dispatch(.vpnUpdatePushResult(true))
                loadResultNativeAD(in: store)
            })

            
            store.dispatch(.event(.vpnResultDisconnected))
            store.dispatch(.event(.vpnConnectedDate, ["duration": "\(ceil(Date().timeIntervalSince1970 - store.state.vpn.date.timeIntervalSince1970))"]))
        }
    }
    
    func loadResultNativeAD(in store: AppStore) {
        if store.state.vpn.state == .connected {
            store.dispatch(.event(.connectResultAD))
            if store.state.ad.isLoaded(.vpnResult) {
                store.dispatch(.event(.connectResultShowAD))
            }
        } else if store.state.vpn.state == .disconnected {
            store.dispatch(.event(.disconnectResultAD))
            if store.state.ad.isLoaded(.vpnResult) {
                store.dispatch(.event(.disconnectResultShowAD))
            }
        }
        
        store.dispatch(.rootUpdateLoadPostion(.vpnResult))
        store.dispatch(.adDisappear(.vpnResult))
        store.dispatch(.adLoad(.vpnResult, .vpnResult))
    }
}


struct ConnectingSceneCommand: AppCommand {
    func execute(in store: AppStore) {
        store.dispatch(.adLoad(.vpnConnect))
        if store.state.root.isUserGo {
            store.dispatch(.adLoad(.vpnBack))
        }
    }
}
