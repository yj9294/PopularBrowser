//
//  VPNModel.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import Foundation
import UIKit

//struct VPNCountryModel: Codable, Equatable, Hashable {
//    var country: String
//    var city: String
//    var icon: String
//    var ip: String
//    var port: String
//    var password: String
//    var weights: Int
//    var delay: Double?
//    
//    var title: String {
//        return self.isSmart ? city : "\(country)-\(city)"
//    }
//    
//    var image: String {
//        if UIImage(named: icon) == nil {
//            return "country_unknow"
//        } else {
//            return icon
//        }
//    }
//    
//    static let smart: VPNCountryModel = VPNCountryModel(country: "", city: "Smart server", icon: "country_fastest", ip: "", port: "", password: "", weights: 0)
//    
//    var isSmart: Bool {
//        self == .smart
//    }
//    
//    static func smartModel(with models: [Self]) -> VPNCountryModel? {
//        debugPrint("[server] 开始查找 smart 服务器")
//        debugPrint("[server] 开始随机")
//        let totalWeight: Double = Double(models.map({$0.weights}).reduce(0, +))
//        let random = Double(arc4random() % 100)
//        debugPrint("[server] 随机数：\(Int(random))")
//        var start = 0.0
//        var end = 0.0
//        return models.filter{ m in
//            let alt = Double(m.weights) / totalWeight * 100
//            end = start + alt
//            debugPrint("[server] ip: \(m.ip) 权重: \(m.weights), \(Int(alt))%")
//            if random >= start, random < end {
//                return true
//            } else {
//                start = end
//                return false
//            }
//        }.first
//    }
//}
