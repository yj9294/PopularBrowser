//
//  CleanView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct CleanView: View {
    @EnvironmentObject var store: AppStore
    var dismissHandle: (()->Void)? = nil
    @State var isAnimation = false
    @State var isShowAD = false
    var body: some View {
        VStack(spacing: 100){
            Spacer()
            HStack{
                Spacer()
                ZStack {
                    Image("clean_animation").rotationEffect(Angle(degrees: isAnimation ? 360.0 : 0.0))
                    Image("clean_icon")
                }
                Spacer()
            }
            Text("Cleaning...").foregroundColor(.white)
            Spacer()
        }.background(Image("launch_bg").resizable().ignoresSafeArea()).onAppear{
            viewDidAppear()
        }
    }
}

extension CleanView {
    @MainActor
    func viewDidAppear() {
        withAnimation(.linear(duration: 3).repeatForever()) {
            isAnimation = !isAnimation
        }
        let token = SubscriptionToken()
        var progress = 0.0
        Timer.publish(every: 0.01, on: .main, in: .common).autoconnect().sink { _ in
            progress += 0.01 / 15
            if isShowAD {
                token.unseal()
                return
            }
            if  store.state.root.selection == .launching {
                token.unseal()
                return
            }
            if progress > 0.3, store.state.ad.isLoaded(.interstitial), store.state.root.selection == .launched {
                isShowAD = true
                token.unseal()
                store.dispatch(.adShow(.interstitial){ _ in
                    dismiss()
                })
            }
        }.seal(in: token)
        Task {
            if !Task.isCancelled {
                try await Task.sleep(nanoseconds: 12_000_000_000)
                if !isShowAD, store.state.root.selection == .launched {
                    token.unseal()
                    isShowAD = true
                    dismiss()
                }
            }
        }
    }
    
    func dismiss() {
        SheetKit().dismiss(){
            store.dispatch(.dismiss)
            self.dismissHandle?()
        }
    }
}

struct CleanView_Previews: PreviewProvider {
    static var previews: some View {
        CleanView()
    }
}
