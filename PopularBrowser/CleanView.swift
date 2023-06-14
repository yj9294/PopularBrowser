//
//  CleanView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct CleanView: View {
    var dismissHandle: (()->Void)? = nil
    @State var isAnimation = false
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
        Task {
            if !Task.isCancelled {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                SheetKit().dismiss(){
                    self.dismissHandle?()
                }
            }
        }
    }
}

struct CleanView_Previews: PreviewProvider {
    static var previews: some View {
        CleanView()
    }
}
