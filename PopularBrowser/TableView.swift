//
//  TabView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct TableView: View {
    var dismissHandle: (()->Void)? = nil
    @EnvironmentObject var store: AppStore
    let colums = [GridItem(.flexible(minimum: 150, maximum: 200), spacing: 16), GridItem(.flexible(minimum: 150, maximum: 200), spacing: 16)]

    var body: some View {
        VStack{
            HStack{
                Button(action: back) {
                    Image("back").padding(.leading, 16)
                }
                Spacer()
            }.frame(height: 56)
            ScrollView {
                LazyVGrid(columns: colums, spacing: 16){
                    ForEach(store.state.browser.browsers, id: \.self) { item in
                        Button {
                            select(item)
                        } label: {
                            VStack(spacing: 40){
                                HStack{
                                    Spacer()
                                    Button {
                                        delete(item)
                                    } label: {
                                        Image("delete").padding(.top, 10)
                                    }.opacity(store.state.browser.browsers.count == 1 ? 0.0 : 1.0)
                                }.padding(.horizontal, 8).padding(.top, 12)
                                Image("launch_icon")
                                Text(item.webView.url?.absoluteString ?? "").padding(.horizontal, 20).font(.system(size: 9.0)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.center)
                                Spacer()
                            }.frame(height: 220).cornerRadius(8).background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill( item.isSelect ? Color("#FA44B2") : .gray)
                                )
                        }.background(Color.white)
                    }
                }
                .padding(.all, 20)
            }
            HStack{
                NativeADView(model: store.state.root.adModel)
            }.padding(.horizontal, 16).frame(height: 120)
            Spacer()
            ZStack {
                HStack{
                    Spacer()
                    Button(action: back) {
                        Text("Back").padding(.trailing, 16)
                    }.foregroundColor(Color("#333333"))
                }.frame(height: 56)
                Button(action: add) {
                    Image("new")
                }
            }
        }.onAppear{viewDidAppear()}
    }
}

extension TableView {
    func viewDidAppear(){
        store.dispatch(.event(.tabShow))
        store.dispatch(.adLoad(.native, .tab))
    }
    func back() {
        store.dispatch(.adDisappear(.native))
        SheetKit().dismiss()
        dismissHandle?()
    }
    
    func add() {
        back()
        store.dispatch(.add(.navigation))
        store.dispatch(.browser)
        store.dispatch(.event(.webNew, ["bro": "tab"]))
    }
    
    func delete(_ item: Browser) {
        store.dispatch(.delete(item))
        store.dispatch(.browser)
    }
    
    func select(_ item: Browser) {
        back()
        store.dispatch(.select(item))
        store.dispatch(.browser)
    }
}

struct TableView_Previews: PreviewProvider {
    static var previews: some View {
        TableView().environmentObject(AppStore())
    }
}
