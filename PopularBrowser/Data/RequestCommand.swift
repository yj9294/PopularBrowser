//
//  RequestCommand.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import Foundation
import Reachability

//{
//  "ip": "166.0.236.212",
//  "city": "Fremont",
//  "region": "California",
//  "country": "US",
//  "loc": "37.5483,-121.9886",
//  "org": "AS6939 Hurricane Electric LLC",
//  "postal": "94536",
//  "timezone": "America/Los_Angeles",
//  "readme": "https://ipinfo.io/missingauth"
//}
struct IPResponse: Codable {
    var ip: String?
    var city: String?
    var country: String?
}

// 请求当前本地IP
struct RequestIPCommand: AppCommand {
    func execute(in store: AppStore) {
        requestIP(in: store)
    }
    
    func requestIP(in store: AppStore) {
        let token = SubscriptionToken()
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://ipinfo.io/json")!).map({
            $0.data
        }).eraseToAnyPublisher().decode(type: IPResponse.self, decoder: JSONDecoder()).sink { complete in
            if case .failure(let error) = complete {
                debugPrint("[IP] err:\(error)")
            }
            token.unseal()
        } receiveValue: {response in
            if response.country == "CN" {
                store.dispatch(.rootUpdateIPError(true))
            }
        }.seal(in: token)
    }

}

