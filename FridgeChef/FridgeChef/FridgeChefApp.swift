//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import SwiftUI
import Firebase
import IQKeyboardManagerSwift

// 使用 AppDelegate 來初始化 Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        return true
    }
}

@main
struct FridgeChefApp: App {
    // 註冊 AppDelegate 以初始化 Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
//            LoginView() // 起始頁面可以是你的註冊頁面
            MainTabView()
        }
    }
    init() {
        configureKeyboardManager()
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 30)!]
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
        navBarAppearance.backgroundColor = .white
        navBarAppearance.backgroundEffect = .none
        navBarAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    private func configureKeyboardManager() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false  // Disable/enable the toolbar as per your need
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }
}
