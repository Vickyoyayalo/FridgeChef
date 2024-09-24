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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color("NavigationBarTitle")  // 设置整个视图背景
                    .edgesIgnoringSafeArea(.all)  // 忽略安全区域，覆盖整个屏幕
                TabView(selection: $selectedTabIndex) {
                    HomeView()
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
                    
                    RecipeView(recipeManager: RecipeManager())
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
            }
            // 中心的浮起按钮，带有自定义Logo
            Button(action: {
                selectedTabIndex = 2 // 这将导航到 ChatView
            }) {
                Image("Chat") // 这里使用你的 Logo 图片
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .shadow(radius: 10)
            }
            .offset(y: 0) // 将按钮向上浮起一点
            .accessibility(label: Text("Chat"))
            .zIndex(1) // 确保这个按钮在最前面
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
