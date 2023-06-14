//
//  SettingView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct SettingView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.openURL) private var openURL
    var privacyHandle: (()->Void)? = nil
    var termsHandle: (()->Void)? = nil
    var shareHandle: (()->Void)? = nil
    var copyHandle: (()->Void)? = nil
    var body: some View {
        VStack {
            HStack{Spacer()}
            Spacer()
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 12){
                        HStack(spacing:44){
                            Button(action: new) {
                                VStack(spacing: 5){
                                    Image("add")
                                    Text("New").font(.system(size: 14.0))
                                }
                            }.foregroundColor(Color("#333333"))
                            Button(action: share) {
                                VStack(spacing: 5){
                                    Image("share")
                                    Text("Share").font(.system(size: 14.0))
                                }
                            }.foregroundColor(Color("#333333"))
                            Button(action: copy) {
                                VStack(spacing: 5){
                                    Image("copy")
                                    Text("Copy").font(.system(size: 14.0))
                                }
                            }.foregroundColor(Color("#333333"))
                        }
                        Button(action: rate) {
                            HStack{
                                Text("Rate us").foregroundColor(Color("#9C9C9C")).font(.system(size: 14))
                                Spacer()
                                Image("arrow")
                            }
                        }.cellStyle()
                        Button(action: terms) {
                            HStack{
                                Text("Terms of Userss").foregroundColor(Color("#9C9C9C")).font(.system(size: 14))
                                Spacer()
                                Image("arrow")
                            }
                        }.cellStyle()
                        Button(action: privacy) {
                            HStack{
                                Text("Privacy Policy").foregroundColor(Color("#9C9C9C")).font(.system(size: 14))
                                Spacer()
                                Image("arrow")
                            }
                        }.cellStyle()
                    }.frame(width: 264, height: 266).background(RoundedRectangle(cornerRadius: 12).fill(Color("#FFF1EE")))
                }.padding(.trailing, 20)
            }.padding(.bottom, 50)
        }.background(Color.black.opacity(0.01).onTapGesture {
            SheetKit().dismiss()
        })
    }
}

struct SettingCellModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.horizontal, 20).padding(.vertical, 12).background(Color.white.cornerRadius(8)).padding(.horizontal, 12)
    }
}

extension View {
    func cellStyle() -> some View {
        self.modifier(SettingCellModifier())
    }
}

extension SettingView {
    func rate() {
        SheetKit().dismiss()
        if let url = URL(string: "https://itunes.apple.com/cn/app/id6448264938") {
            openURL(url)
        }
    }
    
    func privacy() {
        SheetKit().dismiss {
            self.privacyHandle?()
        }
    }
    
    func terms() {
        SheetKit().dismiss {
            self.termsHandle?()
        }
    }
    
    func share() {
        SheetKit().dismiss() {
            self.shareHandle?()
        }
    }
    
    func copy() {
        SheetKit().dismiss() {
            self.copyHandle?()
        }
    }
    
    func new() {
        SheetKit().dismiss()
        store.dispatch(.add(.navigation))
        store.dispatch(.browser)
        store.dispatch(.event(.webNew, ["bro": "setting"]))
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView().environmentObject(AppStore())
    }
}
