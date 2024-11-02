//
//  FridgeChefApp.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import UIKit
import SwiftUI
import FirebaseAuth
import Firebase
import UserNotifications
import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        APIKeyManager.shared.initializeAPIKeys()
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase has been configured successfully.")
            
            let settings = Firestore.firestore().settings
            settings.cacheSettings = PersistentCacheSettings()
            Firestore.firestore().settings = settings
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let currentUser = Auth.auth().currentUser {
                print("User is logged in with UID: \(currentUser.uid)")
            } else {
                print("No user is currently logged in.")
            }
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, _) in
            if granted {
                print("User notifications are allowed.")
            } else {
                print("User notifications are not allowed.")
            }
        }
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange,
            .font: UIFont(name: "ArialRoundedMTBold", size: 30)!
        ]
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(named: "NavigationBarTitle") ?? UIColor.systemRed,
            .font: UIFont(name: "ArialRoundedMTBold", size: 20)!
        ]
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
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
}

func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    
    if response.actionIdentifier == "foodpin.makeReservation" {
        print("Make reservation...")
        if let phone = response.notification.request.content.userInfo["phone"] {
            let telURL = "tel://\(phone)"
            if let url = URL(string: telURL) {
                if UIApplication.shared.canOpenURL(url) {
                    print("calling \(telURL)")
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    completionHandler()
}

func createGradientImage(colors: [UIColor], size: CGSize, opacity: CGFloat) -> UIImage? {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = CGRect(origin: .zero, size: size)
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

@main
struct FridgeChefApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var foodItemStore = FoodItemStore()
    @StateObject private var viewModel = RecipeSearchViewModel()
    @AppStorage("hasSeenTutorial") var hasSeenTutorial: Bool = false
    @AppStorage("log_Status") var isLoggedIn: Bool = false
    
    //    init() {
    //        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
    //    }
    
    var body: some Scene {
        WindowGroup {
            if !hasSeenTutorial {
                TutorialView(viewModel: viewModel, foodItemStore: foodItemStore)
                    .onDisappear {
                        hasSeenTutorial = true
                    }
                    .font(.custom("ArialRoundedMTBold", size: 18))
                    .preferredColorScheme(.light)
            } else if isLoggedIn {
                MainTabView(viewModel: viewModel, foodItemStore: foodItemStore)
                    .font(.custom("ArialRoundedMTBold", size: 18))
                    .preferredColorScheme(.light)
            } else {
                LoginView(viewModel: viewModel, foodItemStore: foodItemStore)
                    .font(.custom("ArialRoundedMTBold", size: 18))
                    .preferredColorScheme(.light)
            }
        }
    }
}
