//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import SwiftUI
import IQKeyboardManagerSwift
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }
}

@main
struct FridgeChefApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("log_Status") var isLoggedIn: Bool = false  // 使用 AppStorage 来监听登录状态

    @StateObject private var viewModel = RecipeSearchViewModel()

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
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
                    .environmentObject(viewModel)// 如果已登录，显示主界面
            } else {
                LoginView()  // 如果未登录，显示登录界面
                    .environmentObject(viewModel)
                
            }
        }
    }
    
    private func configureKeyboardManager() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }
}

//import UIKit
//import Firebase
//
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//        return true
//    }
//}
//
//import SwiftUI
//import IQKeyboardManagerSwift
//
//@main
//struct FridgeChefApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    @StateObject private var viewModel = RecipeSearchViewModel()
//
//    init() {
//        configureKeyboardManager()
//
//        let navBarAppearance = UINavigationBarAppearance()
//        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 30)!]
//        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
//        navBarAppearance.backgroundColor = .white
//        navBarAppearance.backgroundEffect = .none
//        navBarAppearance.shadowColor = .clear
//
//        UINavigationBar.appearance().standardAppearance = navBarAppearance
//        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
//        UINavigationBar.appearance().compactAppearance = navBarAppearance
//    }
//
//    var body: some Scene {
//        WindowGroup {
//            LoginView()
//                .environmentObject(viewModel)
//        }
//    }
//
//    private func configureKeyboardManager() {
//        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.enableAutoToolbar = false
//        IQKeyboardManager.shared.resignOnTouchOutside = true
//    }
//}


//import SwiftUI
//import Firebase
//import IQKeyboardManagerSwift
//
//// 使用 AppDelegate 來初始化 Firebase
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//        
//        if FirebaseApp.app() == nil {
//            FirebaseApp.configure()
//        }
//        
//        return true
//    }
//}
//
//@main
//struct FridgeChefApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @StateObject private var viewModel = RecipeSearchViewModel()
//    var body: some Scene {
//        WindowGroup {
//            LoginView()
//                .environmentObject(viewModel)
//        }
//    }
//    init() {
//        configureKeyboardManager()
//        
//        let navBarAppearance = UINavigationBarAppearance()
//        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 30)!]
//        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
//        navBarAppearance.backgroundColor = .white
//        navBarAppearance.backgroundEffect = .none
//        navBarAppearance.shadowColor = .clear
//        
//        UINavigationBar.appearance().standardAppearance = navBarAppearance
//        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
//        UINavigationBar.appearance().compactAppearance = navBarAppearance
//    }
//    
//    private func configureKeyboardManager() {
//        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.enableAutoToolbar = false  // Disable/enable the toolbar as per your need
//        IQKeyboardManager.shared.resignOnTouchOutside = true
//    }
//}
