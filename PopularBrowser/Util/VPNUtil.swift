//
//  VPNUtil.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import UIKit
import NetworkExtension
import Foundation

protocol VPNStateChangedObserver: NSObjectProtocol {
    func onStateChangedTo(state: VPNUtil.VPNState)
}

enum VPNConnectState {
    case idle
    case preparing
    case testing
    case connecting
    case connected
    case disconnecting
    case disconnected
}

class VPNUtil: NSObject {

    enum VPNState: String {
        case idle
        case connecting
        case connected
        case disconnecting
        case disconnected
        case error
        var title: String {
            if self != .idle, self != .error, self != .disconnected {
                return self.rawValue.capitalized
            }
            return "Connect"
        }
    }

    enum NEVPNManagerState {
        case loading
        case idle
        case preparing
        case ready
        case error
    }
    
    public static let shared = VPNUtil()

    private var manager: NETunnelProviderManager? = nil {
        didSet {
            if manager != nil {
                updateVPNStatus()
            }
        }
    }

    private var statusOfVPNObserverAdded = false
    private var needConnectAfterLoaded = false
    private var connectedEver = true
    
    /// 链接时长
    var connectingTimer: Timer? = nil

    /// vpn状态监听的观察者
    var stateObservers = [VPNStateChangedObserver]()

    /// 扩展返回的vpn状态
    var vpnState: VPNState = .idle {
        didSet {
            if oldValue == vpnState {
                return
            }
        }
    }
    /// manager stage change
    var managerState: NEVPNManagerState = .loading {
        didSet {
            if oldValue == managerState {
                return
            }
        }
    }
    
    // 链接时间
    var connectedAt: Date? {
        return manager?.connection.connectedDate
    }

    @objc private func updateVPNStatus(timeout: Bool = false) {
        guard let session = manager?.connection as? NETunnelProviderSession else  {
            debugPrint("[VPN MANAGER] cannot got session but updateVPNStatus called!")
            return
        }


        if !connectedEver && session.status != .disconnected {
            debugPrint("[VPN MANAGER] not connected yet, but status is \(session.status.rawValue)")
            return
        }
        
        let arr = ["invalid","disconnected","connecting","connected","reasserting","disconnecting"]
        debugPrint("[VPN MANAGER] vpn status changed to: \(arr[session.status.rawValue])")

        switch session.status {
        case .connecting:
            vpnState = .connecting
        case .connected:
            vpnState = .connected
        case .disconnecting:
            vpnState = .disconnecting
        case .disconnected:
            vpnState = .disconnected
        case .invalid:
            vpnState = .error
        default:
            vpnState = .idle
        }
        if session.status != .connecting {
            debugPrint("[VPN MANAGER] status changed: \(arr[session.status.rawValue]), clear timer.")
            connectingTimer?.invalidate()
            connectingTimer = nil
        }

        if timeout && session.status != .connected {
            vpnState = .error
        }
        
        self.makeSureRunInMainThread {
            self.stateObservers.forEach {
                $0.onStateChangedTo(state: self.vpnState)
            }
        }
    }
}

//MARK: - 链接相关的操作
extension VPNUtil {
    
    // 链接vpn操作
    func connect(options: [String : NSObject]?) {

        guard let manager = manager else {
            debugPrint("[VPN MANAGER] manager is nil, cannot connect")
            vpnState = .error
            return
        }

        // add timeout timer
        connectingTimer = Timer(timeInterval: AppUtil.connectTimeout, repeats: false) { [unowned self] timer in
            self.connectTimeout()
        }
        RunLoop.main.add(connectingTimer!, forMode: .default)
        
        if !manager.isEnabled {
            debugPrint("[VPN MANAGER] manager is not enabled")
            needConnectAfterLoaded = true
            manager.loadFromPreferences { error in
                if let error = error {
                    debugPrint("[VPN MANAGER] cannot enable mananger: \(error.localizedDescription)")
                    self.managerState = .error
                } else {
                    manager.isEnabled = true
                    manager.saveToPreferences { error in
                        if let error = error {
                            debugPrint("[VPN MANAGER] cannot save manager into preferences: \(error.localizedDescription)")
                            self.managerState = .error
                        } else {
                            self.startVPNTunnel(options: options)
                        }
                    }
                }
            }
        } else {
            startVPNTunnel(options: options)
        }
    }
    

    // 关闭VPN操作
    func stopVPN() {
        guard let connection = manager?.connection, connection.status != .disconnected else {
            self.makeSureRunInMainThread {
                self.stateObservers.forEach {
                    $0.onStateChangedTo(state: .disconnected)
                }
            }
            return
        }
        connection.stopVPNTunnel()
    }

    private func startVPNTunnel(options: [String : NSObject]?) {
        guard let manager = manager else {
            debugPrint("[VPN MANAGER] manager is nil, cannot connect")
            return
        }
        do {
            try manager.connection.startVPNTunnel(options: options)
            connectedEver = true
            addVPNStatusDidChangeObserver()
        } catch {
            debugPrint("[VPN MANAGER] Start VPN failed \(error.localizedDescription)")
        }
    }
    
}
//MARK: - 观察VPN和Manager状态的变化
extension VPNUtil {
    
    func addStateObserver(_ observer: VPNStateChangedObserver) {
        self.makeSureRunInMainThread {
            if self.stateObservers.contains(where: {$0 === observer}) {
                debugPrint("[VPN MANAGER] already added this observer")
                return
            }
            self.stateObservers.append(observer)
        }
    }

    func removeStateObserver(_ observer: VPNStateChangedObserver) {
        self.makeSureRunInMainThread {
            self.stateObservers.removeAll(where: { $0 === observer })
        }
    }
    
    private func addVPNStatusDidChangeObserver() {
        if statusOfVPNObserverAdded {return}
        guard manager != nil else {return}
        statusOfVPNObserverAdded = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateVPNStatus), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }

    private func removeVPNStatusDidChangeObserver() {
        if statusOfVPNObserverAdded {
            statusOfVPNObserverAdded = false
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        }
    }
    
    private func connectTimeout() {
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
//            if self.manager?.connection.status != NEVPNStatus.connected {
//                debugPrint("[VPN MANAGER] connect timeout,stopVPNTunnel.")
//                self.manager?.connection.stopVPNTunnel()
//            }
//            self.updateVPNStatus(timeout: true)
//        }
    }
}
//MARK: - VPN配置相关的方法
extension VPNUtil {
    func create(completionHandler: ((Error?) -> Void)? = nil) {
        let manager = NETunnelProviderManager()
        manager.isEnabled = true
        let p = NETunnelProviderProtocol()
        p.serverAddress = AppUtil.name
        p.providerBundleIdentifier = AppUtil.proxy
        p.providerConfiguration = ["manager_version": "manager_v1"]
        manager.protocolConfiguration = p
        connectedEver = false
        manager.loadFromPreferences { (error) in
            if let error = error {
                debugPrint("[VPN MANAGER] create failed: \(error.localizedDescription)")
                self.managerState = .error
                completionHandler?(error)
                return
            }
            manager.saveToPreferences(completionHandler: { (error: Error?) in
                if let error = error {
                    debugPrint("[VPN MANAGER] code: \(NEVPNError.Code.configurationReadWriteFailed.rawValue)")
                    debugPrint("[VPN MANAGER] code: \(NEVPNError.Code.configurationStale.rawValue)")
                    debugPrint("[VPN MANAGER] create failed: \(error.localizedDescription)")
                    self.managerState = .error
                    completionHandler?(error)
                } else {
                    completionHandler?(nil)
                    self.load()
                }
            })
        }
    }

    func load() {
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let error = error {
                debugPrint("[VPN MANAGER] cannot load manangers from preferences: \(error.localizedDescription)")
                self.managerState = .error
                self.connectedEver = false
                return
            }

            guard let managers = managers, let manager = managers.first else {
                debugPrint("[VPN MANAGER] have no manager")
                self.managerState = .idle
                self.connectedEver = false
                return
            }

            manager.loadFromPreferences { error in
                if let error = error {
                    debugPrint("[VPN MANAGER] cannot load manager from preferences: \(error.localizedDescription))")
                    self.managerState = .error
                }

                debugPrint("[VPN MANAGER] manager loaded from preferences")
                self.manager = manager
                self.managerState = .ready
                self.removeVPNStatusDidChangeObserver()
                self.addVPNStatusDidChangeObserver()
            }
        }
    }

    func prepareForLoading(completionHandler: @escaping (() -> Void)) {
        DispatchQueue.global().async {
            var times = 20
            while times > 0 {
                times -= 1
                if self.managerState != .loading {
                    self.makeSureRunInMainThread {
                        completionHandler()
                    }
                    return
                }

                Thread.sleep(forTimeInterval: 0.2)
            }
            self.makeSureRunInMainThread {
                completionHandler()
            }
        }
    }
}

extension VPNUtil {
    func makeSureRunInMainThread(job: @escaping () -> Void) {
        if Thread.current.isMainThread {
            job()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                job()
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}
