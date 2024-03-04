//
//  GuideView.swift
//  PopularBrowser
//
//  Created by hero on 1/3/2024.
//

import SwiftUI

struct GuideView: View {
    let action: ()->Void
    let skip: ()->Void
    @State var time: Int = 5
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var color: Color {
        time > 0 ? Color("#BBCDD9") : Color.white
    }
    var title: String {
        time > 0 ? "Skip \(time)s" : "Skip"
    }
    var body: some View {
        VStack {
            HStack{
                Spacer()
                Button(action: {
                    if time == 0 {
                        skip()
                    }
                }, label: {
                    Text(title).padding(.horizontal, 16).padding(.vertical, 6).foregroundColor(color).font(.system(size: 13))
                }).foregroundColor(color).padding(.trailing, 12).padding(.top, 6)
            }
            Spacer()
            VStack(spacing: 20){
                Image("guide_icon")
                Text("Open Popular VPN to protect your network and prevent being tracked.").foregroundStyle(.white).font(.system(size: 17)).multilineTextAlignment(.center)
            }.padding(.horizontal, 50)
            Button {
                action()
            } label: {
                HStack {
                    Spacer()
                    Text("Confirm").foregroundStyle(.white).font(.system(size: 16.0)).padding(.vertical, 15)
                    Spacer()
                }
            }.background(.linearGradient(colors: [Color("#C163F8"), Color("#A328E2")], startPoint: .leading, endPoint: .trailing)).cornerRadius(26).padding(.horizontal, 60).padding(.top, 60)
            Spacer()
        }.background(Image("guide_bg").resizable().ignoresSafeArea()).onReceive(timer) { _ in
            if self.time > 0 {
                self.time -= 1
            }
        }
    }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView(action: {}, skip: {})
    }
}
