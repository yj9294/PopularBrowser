//
//  AppUtil.swift
//  PopularBrowser
//
//  Created by Super on 2024/2/29.
//

import Foundation
import UIKit

struct AppUtil {
    static let isDebug = (Bundle.main.bundleIdentifier ?? "") != "com.popularSearch.browsers.fast"
    static var rootVC: UIViewController? {
        (UIApplication.shared.connectedScenes.filter({$0 is UIWindowScene}).first as? UIWindowScene)?.windows.filter({$0.isKeyWindow}).first?.rootViewController
    }
}
