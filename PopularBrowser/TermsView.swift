//
//  TermsView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct TermsView: View {
    var body: some View {
        VStack{
            ZStack {
                HStack{
                    Button(action: back) {
                        Image("back_1").padding(.leading,16)
                    }
                    Spacer()
                }.frame(height: 44)
                Text("Terms of User").font(.system(size: 15)).foregroundColor(Color("#333333"))
            }
            ScrollView{
                Text("""
Whether you are a new or existing user of our products and services, we hope you will take some time to familiarize yourself with our Terms of Use. By using our software and services, you hereby agree to accept these terms. If you do not accept these terms, please do not use our software and services.
Use of the application
1.You may not use our applications for unauthorized commercial purposes or use our applications and services for illegal purposes.
2.You agree that we may discontinue some or all of our services at any time without prior notice to you.
3.you agree that we are not responsible for third party content that you access using our applications.
Update
We will revise, update and change our privacy policy from time to time.
Contact us
If you would like further information on the collection, use, disclosure, transfer or processing of your Personal Data or the exercise of any of the rights listed above, please contact us through the specific channels indicated below.
developer@cdgsgx.com.
""").padding(.horizontal, 16)
            }
            Spacer()
        }
    }
}

extension TermsView{
    func back() {
        SheetKit().dismiss()
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
    }
}
