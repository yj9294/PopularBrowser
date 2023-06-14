//
//  AppAction.swift
//  PopularBrowser
//
//  Created by yangjian on 2023/6/8.
//

import Foundation

enum AppAction {
    case rootSelection(AppState.RootState.Index)
    case browser
    case hideKeyboard
    case loadURL(String)
    case stopLoad
    case delete(Browser)
    case select(Browser)
    case add(Browser)
    case copy
    case clean
    
    case event(AppState.FirebaseState.Event, [String: String]? = nil)
    case property(AppState.FirebaseState.Property)
}
