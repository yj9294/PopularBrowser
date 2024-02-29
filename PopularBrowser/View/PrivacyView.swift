//
//  PrivacyView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI
import SheetKit

struct PrivacyView: View {
    var handle:(()->Void)? = nil
    var body: some View {
        VStack{
            ZStack {
                HStack{
                    Button(action: back) {
                        Image("back_1").padding(.leading,16)
                    }
                    Spacer()
                }.frame(height: 44)
                Text("Privacy Policy").font(.system(size: 15)).foregroundColor(Color("#333333"))
            }
            ScrollView{
                Text("""
Privacy Policy

Whether you are a new or existing user of our products, we encourage you to take some time to familiarize yourself with our privacy policy.

When you use our services, we have implemented various procedures to protect your privacy. However, in order to enhance your experience, we may collect some information from you.

We may periodically update this Privacy Statement to reflect changes in the way we collect and use your personal data or changes in applicable law.

What information will we collect

To enhance your experience, we may collect some information from you, and this collection will only be for legitimate purposes.

We collect some standard information that browsers are usually required to provide, such as: browser type, language preference, etc.Non-personal data is information that does not personally identify you. We may collect non-personal data, such as your device model, operating system version, country code and other attributes.

This non-personal information is collected so that we can better understand how you use our products.

How we will use the information

Your personal information may be used in the following ways: to improve the experience of our browser services, to check and resolve potential problems.

In general, personal information submitted to us is used to respond to user feedback and requests, or to help us enhance our customer service.Statistical analysis of user preferences; for editorial and feedback purposes; to improve content and assist in product development; and to improve the browser's service management and service experience.

How we share information

We may share your personal information internally.

Certain laws require us to store the information we collect, even after you terminate our services. 

We may share your personal information with trusted partners or service providers.

Update

We may update these terms and conditions from time to time, and your continued use of our services will indicate your acceptance of our updated terms and conditions.

Contact us

If you have any questions about this Privacy Policy, you may contact us using the information below.

developer@cdgsgx.com


Terms of use

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

extension PrivacyView{
    func back() {
        SheetKit().dismiss(completion: handle)
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
