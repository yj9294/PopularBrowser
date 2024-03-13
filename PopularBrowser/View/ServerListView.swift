//
//  ServerListView.swift
//  PopularBrowser
//
//  Created by hero on 11/3/2024.
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0){
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 14) {
                    ForEach(store.state.vpn.getServers.allModels(), id: \.self) { country in
                        Button {
                            connect(country)
                        } label: {
                            HStack(spacing: 12){
                                Image(country.image).frame(width: 28, height: 28)
                                Text(country.title).font(.system(size: 16))
                                Spacer()
                                Image("arrow_right")
                            }.padding(.horizontal, 14).padding(.vertical, 12).background(Color("#FFF4F7")).cornerRadius(12)
                        }
                    }.foregroundColor(Color("#414141"))
                }.padding(.all, 16)
                Spacer()
            }
        }.navigationBarTitleDisplayMode(.inline).toolbar {
            ToolbarItem(placement: .principal) {
                Text("Servers").font(.system(size: 16))
            }
        }
    }
    
    func connect(_ country: CountryModel.Country) {
        store.dispatch(.updateVPNMutaConnect(true))
        store.dispatch(.updateVPNMutaDisconnect(false))
        store.dispatch(.vpnUpdatePushServerView(false))
        store.dispatch(.updateVPNCountry(country))
        store.dispatch(.updateVPNAutoConnect(true))
        store.dispatch(.vpnDisconnect)
    }
}

struct ServerListView_Previews: PreviewProvider {
    static var previews: some View {
        ServerListView()
    }
}
