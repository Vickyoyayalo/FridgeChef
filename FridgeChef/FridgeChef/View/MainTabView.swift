//
//  MainView.swift
//  FoodPin
//
//  Created by Simon Ng on 17/10/2023.
//
//import SwiftUI
//
//struct MainTabView: View {
//    @State private var selectedTabIndex = 0
//    @State private var showChatView = false
//    @ObservedObject private var keyboardResponder = KeyboardResponder()
//    
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            ZStack {
//                Color("NavigationBarTitle")  // 设置整个视图背景
//                    .edgesIgnoringSafeArea(.all)  // 忽略安全区域，覆盖整个屏幕
//                TabView(selection: $selectedTabIndex) {
//                    
//                    RecipeMainView()
//                        .tabItem {
//                            Label("食譜", systemImage: "heart.text.square")
//                        }
//                        .tag(0)
//                    
//                    FridgeView()
//                        .tabItem {
//                            Label("冰箱", systemImage: "refrigerator.fill")
//                        }
//                        .tag(1)
//                    
//                    ChatView()// 占位视图，不实际显示在 TabView 中
//                        .tabItem {
//                            Label("", systemImage: "")
//                        }
//                        .tag(2)
//                    
//                    RecipeMainView()
//                        .tabItem {
//                            Label("收藏", systemImage: "heart.fill")
//                        }
//                        .tag(3)
//                    
//                    GroceryListView()
//                        .tabItem {
//                            Label("採買", systemImage: "storefront.fill")
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
import SwiftUI

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    @State private var showChatView = false
    @State private var showingLogoutConfirmation = false
    @AppStorage("log_Status") private var isLoggedIn: Bool = true  // Track login status for logout functionality

    @ObservedObject private var keyboardResponder = KeyboardResponder()

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTabIndex) {
                    RecipeMainView()
                        .tabItem {
                            Label("食譜", systemImage: "heart.text.square")
                        }
                        .tag(0)
                    
                    FridgeView()
                        .tabItem {
                            Label("冰箱", systemImage: "refrigerator.fill")
                        }
                        .tag(1)
                    
                    ChatView()
                        .tabItem {
                            Label("", systemImage: "")
                        }
                        .tag(2)
                    
                    RecipeMainView()
                        .tabItem {
                            Label("收藏", systemImage: "heart.fill")
                        }
                        .tag(3)
                    
                    GroceryListView()
                        .tabItem {
                            Label("採買", systemImage: "storefront.fill")
                        }
                        .tag(4)
                }
                .navigationTitle("Main View") // Optionally set a title
                .navigationBarItems(trailing: Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    Image(systemName: "power")
                })
                .alert("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
                    Button("Log Out", role: .destructive) {
                        logOut()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .tint(Color("NavigationBarTitle"))
                .padding(.bottom, keyboardResponder.currentHeight)

                Button(action: {
                    selectedTabIndex = 2 // Navigate to ChatView
                }) {
                    Image("Chat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .shadow(radius: 10)
                }
                .offset(y: -keyboardResponder.currentHeight / 2)
                .padding(.bottom, 30)
                .zIndex(1)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    func logOut() {
        // Perform logout operations here
        isLoggedIn = false // Update login status in AppStorage
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
