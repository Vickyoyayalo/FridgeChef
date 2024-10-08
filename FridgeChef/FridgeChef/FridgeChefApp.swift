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

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange, .font: UIFont(name: "ArialRoundedMTBold", size: 30)!]
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed, .font: UIFont(name: "ArialRoundedMTBold", size: 20)!]
        navBarAppearance.shadowColor = nil
        navBarAppearance.shadowImage = UIImage()
        
        if let gradientImage = createGradientImage(colors: [UIColor.systemOrange, UIColor.systemYellow], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.5) {
            navBarAppearance.backgroundImage = gradientImage
        }
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.resignOnTouchOutside = true
        
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
    @StateObject private var foodItemStore = FoodItemStore()
    @StateObject private var viewModel = RecipeSearchViewModel()
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false
    @AppStorage("log_Status") var isLoggedIn: Bool = false
    
//    init() {
//           // 臨時重置 hasSeenTutorial，模擬首次啟動
//           UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
//       }
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenTutorial {
                TutorialView()
                    .onDisappear {
                        hasSeenTutorial = true  // 用戶完成教程後，設定為 true
                    }
                    .environmentObject(viewModel)
                    .environmentObject(foodItemStore)
                    .font(.custom("ArialRoundedMTBold", size: 18))
            } else if isLoggedIn {
                MainTabView()
                    .environmentObject(viewModel)
                    .environmentObject(foodItemStore)
                    .font(.custom("ArialRoundedMTBold", size: 18))
            } else {
                LoginView()
                    .environmentObject(viewModel)
                    .environmentObject(foodItemStore)
                    .font(.custom("ArialRoundedMTBold", size: 18))
            }
        }
    }
}
