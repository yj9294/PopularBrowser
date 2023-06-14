//
//  LaunchingView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import SwiftUI

struct LaunchingView: View {
    @State var progress: Double = 0.0
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
            viewDidAppear()
        }
    }
}

extension LaunchingView {
    func viewDidAppear() {
        let duration = 2.789
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let progress = self.progress + 0.01 / duration
            if progress > 1.0 {
                timer.invalidate()
                self.launched?()
            } else {
                self.progress = progress
            }
        }
    }
}

struct LaunchingView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchingView()
    }
}
