//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import SwiftUI
import Firebase

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
            RecommendRecipeListView()
        }
    }
}
