//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import UIKit
import SwiftUI
import Firebase
import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // 设置导航栏外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 30)!]
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
        navBarAppearance.shadowColor = nil // 这里设置为 nil 来移除分隔线
        navBarAppearance.shadowImage = UIImage() // 这也可以用来移除分隔线
        
        // 创建并设置渐变图像为背景，这里透明度设置为 0.4 作为示例
        if let gradientImage = createGradientImage(colors: [UIColor.systemOrange, UIColor.systemYellow], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.3) {
            navBarAppearance.backgroundImage = gradientImage
        }
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        return true
    }
}

func createGradientImage(colors: [UIColor], size: CGSize, opacity: CGFloat) -> UIImage? {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = CGRect(origin: .zero, size: size)
    // 在这里调整颜色的 alpha 值来控制透明度
    gradientLayer.colors = colors.map { $0.withAlphaComponent(opacity).cgColor }
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)  // Top
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)    // Bottom

    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    gradientLayer.render(in: context)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}


// 确保添加到App的其他部分
@main
struct FridgeChefApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = RecipeSearchViewModel()
    @AppStorage("log_Status") var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView().environmentObject(viewModel)
            } else {
                LoginView().environmentObject(viewModel)
            }
        }
    }
    
    private func configureKeyboardManager() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }
}

//
//import SwiftUI
//import IQKeyboardManagerSwift
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
//@main
//struct FridgeChefApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @AppStorage("log_Status") var isLoggedIn: Bool = false  // 使用 AppStorage 来监听登录状态
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
//            if isLoggedIn {
//                MainTabView()
//                    .environmentObject(viewModel)// 如果已登录，显示主界面
//            } else {
//                LoginView()  // 如果未登录，显示登录界面
//                    .environmentObject(viewModel)
//                
//            }
//        }
//    }
//    
//    private func configureKeyboardManager() {
//        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.enableAutoToolbar = false
//        IQKeyboardManager.shared.resignOnTouchOutside = true
//    }
//}
