//
//  MainView.swift
//  FoodPin
//
//  Created by Simon Ng on 17/10/2023.
//
import SwiftUI

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    @State private var showChatView = false
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color("NavigationBarTitle")  // 设置整个视图背景
                    .edgesIgnoringSafeArea(.all)  // 忽略安全区域，覆盖整个屏幕
                TabView(selection: $selectedTabIndex) {
                    RecipeView(recipeManager: RecipeManager())
                        .tabItem {
                            Label("收藏", systemImage: "heart.fill")
                        }
                        .tag(0)
                    
                    FridgeView()
                        .tabItem {
                            Label("冰箱", systemImage: "refrigerator.fill")
                        }
                        .tag(1)
                    
                    ChatView()// 占位视图，不实际显示在 TabView 中
                        .tabItem {
                            Label("", systemImage: "")
                        }
                        .tag(2)
                    
                    HomeView()
                        .tabItem {
                            Label("食譜", systemImage: "heart.text.square")
                        }
                        .tag(3)
                    
                    GroceryListView()
                        .tabItem {
                            Label("採買", systemImage: "storefront.fill")
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
         // Adjust bottom padding of the entire ZStack based on keyboard
    }
}
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
