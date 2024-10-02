//
//  MainView.swift
//  FoodPin
//
//  Created by Simon Ng on 17/10/2023.
//
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    @State private var showChatView = false
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color("NavigationBarTitle")
                    .edgesIgnoringSafeArea(.all)
                
                TabView(selection: $selectedTabIndex) {
                    
                    MainCollectionView()
                        .tabItem {
                            Label("Main", systemImage: "heart.fill")
                        }
                        .tag(0)
                    
                    FridgeView()
                        .tabItem {
                            Label("Fridge", systemImage: "refrigerator.fill")
                        }
                    
                        .tag(1)
                    
                    ChatView()
                        .tabItem {
                            Label("", systemImage: "")
                        }
                        .tag(2)
                    
                    RecipeMainView()
                        .tabItem {
                            Label("Recipe", systemImage: "heart.text.square")
                        }
                        .tag(3)
                    
                    GroceryListView()
                        .tabItem {
                            Label("Shopping", systemImage: "storefront.fill")
                        }
                    
                        .tag(4)
                }
                .tint(Color("NavigationBarTitle"))
                .padding(.bottom, keyboardResponder.currentHeight)
            }
            
            Button(action: {
                selectedTabIndex = 2 // Navigate to ChatView
            }) {
                Image("Chat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .shadow(radius: 10)
            }
            .offset(y: -keyboardResponder.currentHeight / 2) // Adjust offset based on the keyboard height
            .padding(.bottom, 30) // This padding is constant, additional to any keyboard adjustments
            .zIndex(1) // Ensures the button stays on top
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

//MARK: -TabBar item的默认颜色
//import SwiftUI
//import UIKit
//
//struct MainTabView: View {
//    @State private var selectedTabIndex = 0
//    @State private var showChatView = false
//    @ObservedObject private var keyboardResponder = KeyboardResponder()
//
//    // 初始化时设置 UITabBar 的外观
//    init() {
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//
//        // 使用 createGradientImage 函数来创建渐变图像，并应用到 UITabBar 的背景
//        if let gradientImage = createGradientImage(colors: [UIColor.systemOrange, UIColor.systemYellow], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.3) {
//            appearance.backgroundImage = gradientImage  // 将渐变图像作为背景
//        }
//
//        // 设置TabBar item的默认颜色（未选中状态）
//        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
//        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
//
//        UITabBar.appearance().standardAppearance = appearance
//        if #available(iOS 15.0, *) {
//            UITabBar.appearance().scrollEdgeAppearance = appearance
//        }
//
//        // 移除阴影分隔线
//        UITabBar.appearance().shadowImage = UIImage()
//    }
//
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            ZStack {
//                Color("NavigationBarTitle")
//                    .edgesIgnoringSafeArea(.all)
//
//                TabView(selection: $selectedTabIndex) {
//                    MainCollectionView()
//                        .tabItem {
//                            Label("Main", systemImage: "heart.fill")
//                        }
//                        .tag(0)
//
//                    FridgeView()
//                        .tabItem {
//                            Label("Fridge", systemImage: "refrigerator.fill")
//                        }
//                        .tag(1)
//
//                    ChatView()
//                        .tabItem {
//                            Label("", systemImage: "")
//                        }
//                        .tag(2)
//
//                    RecipeMainView()
//                        .tabItem {
//                            Label("Recipe", systemImage: "heart.text.square")
//                        }
//                        .tag(3)
//
//                    GroceryListView()
//                        .tabItem {
//                            Label("Shopping", systemImage: "storefront.fill")
//                        }
//                        .tag(4)
//                }
//                .tint(Color("NavigationBarTitle"))
//                .padding(.bottom, keyboardResponder.currentHeight)
//            }
//
//            Button(action: {
//                selectedTabIndex = 2 // Navigate to ChatView
//            }) {
//                Image("Chat")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 60, height: 60)
//                    .shadow(radius: 10)
//            }
//            .offset(y: -keyboardResponder.currentHeight / 2) // Adjust offset based on the keyboard height
//            .padding(.bottom, 30) // This padding is constant, additional to any keyboard adjustments
//            .zIndex(1) // Ensures the button stays on top
//        }
//        .edgesIgnoringSafeArea(.all)
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}

//MARK: -ScrollView沒有問題
//
//import SwiftUI
//import UIKit
//
//struct MainTabView: View {
//    @State private var selectedTabIndex = 0
//    @State private var showChatView = false
//    @ObservedObject private var keyboardResponder = KeyboardResponder()
//
//    init() {
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//
//        // 使用 createGradientImage 函數來創建漸變圖像，並應用到 UITabBar 的背景
//        if let gradientImage = createGradientImage(colors: [UIColor.systemYellow, UIColor.systemOrange], size: CGSize(width: UIScreen.main.bounds.width, height: 50), opacity: 0.4) {
//            appearance.backgroundImage = gradientImage  // 將漸變圖像作為背景
//        }
//        UITabBar.appearance().standardAppearance = appearance
//        if #available(iOS 15.0, *) {
//            UITabBar.appearance().scrollEdgeAppearance = appearance
//        }
//
//        UITabBar.appearance().shadowImage = UIImage()
//    }
//    
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            ZStack {
//                Color("NavigationBarTitle")
//                    .edgesIgnoringSafeArea(.all)
//                
//                TabView(selection: $selectedTabIndex) {
//                    
//                    MainCollectionView()
//                        .tabItem {
//                            Label("Main", systemImage: "heart.fill")
//                        }
//                        .tag(0)
//                    
//                    FridgeView()
//                        .tabItem {
//                            Label("Fridge", systemImage: "refrigerator.fill")
//                        }
//                        .tag(1)
//                    
//                    ChatView()
//                        .tabItem {
//                            Label("", systemImage: "")
//                        }
//                        .tag(2)
//                    
//                    RecipeMainView()
//                        .tabItem {
//                            Label("Recipe", systemImage: "heart.text.square")
//                        }
//                        .tag(3)
//                    
//                    GroceryListView()
//                        .tabItem {
//                            Label("Shopping", systemImage: "storefront.fill")
//                        }
//                        .tag(4)
//                }
//                .tint(Color("NavigationBarTitle"))
//                .padding(.bottom, keyboardResponder.currentHeight)
//            }
//            
//            Button(action: {
//                selectedTabIndex = 2 // Navigate to ChatView
//            }) {
//                Image("Chat")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 60, height: 60)
//                    .shadow(radius: 10)
//            }
//            .offset(y: -keyboardResponder.currentHeight / 2) // Adjust offset based on the keyboard height
//            .padding(.bottom, 30) // This padding is constant, additional to any keyboard adjustments
//            .zIndex(1) // Ensures the button stays on top
//        }
//        .edgesIgnoringSafeArea(.all)
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}
//
