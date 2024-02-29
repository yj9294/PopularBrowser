//
//  LaunchingView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI

struct LaunchingView: View {
    @EnvironmentObject var store: AppStore
    var progress: Double {
        store.state.root.progress
    }
    var launched: (()->Void)? = nil
    var body: some View {
        VStack{
            VStack(spacing: 16.0){
                HStack{
                    Spacer()
                    Image("launch_icon")
                    Spacer()
                }
                Image("launch_title")
            }.padding(.top, 150)
            Spacer()
            ProgressView(value: progress, total: 1.0).accentColor(Color.white).padding(.horizontal, 90).padding(.bottom, 32)
        }.background(Image("launch_bg").resizable().ignoresSafeArea()).onAppear{
            if progress == 0.0 {
                viewDidAppear()
            }
        }
    }
}

extension LaunchingView {
    func viewDidAppear() {
        var duration = 12.789
        let token = SubscriptionToken()
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            let progress = self.progress + 0.01 / duration
            if progress > 1.0 {
                token.unseal()
                store.dispatch(.adShow(.interstitial) { _ in
                    self.launched?()
                })
            } else {
                store.state.root.progress = progress
            }
            if progress > 0.3, store.state.ad.isLoaded(.interstitial) {
                duration = 0.1
            }
        }.seal(in: token)
        store.dispatch(.adLoad(.interstitial))
        store.dispatch(.adLoad(.native))
    }
}

struct LaunchingView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchingView()
    }
}
