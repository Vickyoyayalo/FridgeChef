//
//  MainTabView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/10.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    @State private var showChatView = false
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    @ObservedObject var viewModel: RecipeSearchViewModel
    @ObservedObject var foodItemStore: FoodItemStore
    
    init(viewModel: RecipeSearchViewModel, foodItemStore: FoodItemStore) {
        self.viewModel = viewModel
        self.foodItemStore = foodItemStore
        
        let appearance = UITabBarAppearance()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        let customColor = UIColor(hex: "#ccb562")
        
        if let gradientImage = createGradientImage(
            colors: [UIColor.systemOrange, UIColor.systemYellow],
            size: CGSize(width: UIScreen.main.bounds.width, height: 50),
            opacity: 0.4
        ) {
            appearance.backgroundImage = gradientImage
        }
        appearance.stackedLayoutAppearance.normal.iconColor = customColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: customColor]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color("NavigationBarTitle")
                    .edgesIgnoringSafeArea(.all)
                
                TabView(selection: $selectedTabIndex) {
                    // 使用傳入的 viewModel 和 foodItemStore 實例
                    MainCollectionView(viewModel: viewModel, foodItemStore: foodItemStore)
                        .tabItem {
                            Label("Main", systemImage: "heart.fill")
                        }
                        .tag(0)
                    
                    FridgeView(foodItemStore: foodItemStore)
                        .tabItem {
                            Label("Fridge", systemImage: "refrigerator.fill")
                        }
                        .tag(1)
                    
                    ChatView(foodItemStore: foodItemStore)
                        .tabItem {
                            Label("", systemImage: "")
                        }
                        .tag(2)
                    
                    RecipeMainView(viewModel: viewModel, foodItemStore: foodItemStore)
                        .tabItem {
                            Label("Recipe", systemImage: "heart.text.square")
                        }
                        .tag(3)
                    
                    GroceryListView(foodItemStore: foodItemStore)
                        .tabItem {
                            Label("Shopping", systemImage: "storefront.fill")
                        }
                        .tag(4)
                }
                .tint(Color("NavigationBarTitle"))
                .padding(.bottom, keyboardResponder.currentHeight)
            }
            
            Button(action: {
                selectedTabIndex = 2
            }, label: {
                Image("CenterChat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 130)
                    .shadow(radius: 5)
            })
            .offset(y: -keyboardResponder.currentHeight / 2)
            .padding(.bottom, -5)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(
            viewModel: RecipeSearchViewModel(),
            foodItemStore: FoodItemStore()
        )
    }
}
