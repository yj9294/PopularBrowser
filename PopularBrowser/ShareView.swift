//
//  ShareView.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/9.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    
    let url: String
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
}

