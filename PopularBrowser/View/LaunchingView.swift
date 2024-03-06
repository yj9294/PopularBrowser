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
        }.background(Image("launch_bg").resizable().ignoresSafeArea())
    }
}

struct LaunchingView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchingView()
    }
}
