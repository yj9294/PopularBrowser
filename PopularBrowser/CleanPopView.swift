//
//  CleanPopView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct CleanPopView: View {
    var dismissHandle: (()->Void)? = nil
    var body: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
            }
            VStack(spacing: 0){
                Image("clean_title").padding(.top, 28)
                Text("Close Tabs and Clear Data").foregroundColor(Color("#333333")).padding(.top, 20)
                Button(action: certain) {
                    ZStack{
                        Image("clean_btn")
                        Text("CLEAN").foregroundColor(.white)
                    }
                }.padding(.top, 18)
                Button(action: back) {
                    Text("Cancel").foregroundColor(Color("#B0B0B0")).font(.system(size: 14.0)).padding(.top, 8).padding(.bottom, 22)
                }
            }.padding(.horizontal, 30).background(Color.white.cornerRadius(10))
            Spacer()
        }
    }
}
extension CleanPopView {
    func certain() {
        SheetKit().dismiss() {
            self.dismissHandle?()
        }
    }
    
    func back() {
        SheetKit().dismiss()
    }
}

struct CleanPopView_Previews: PreviewProvider {
    static var previews: some View {
        CleanPopView()
    }
}
