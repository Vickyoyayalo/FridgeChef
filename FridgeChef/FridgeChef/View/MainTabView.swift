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

//import SwiftUI
//
//struct MainTabView: View {
//
//    @State private var selectedTabIndex = 0
//
//    var body: some View {
//        TabView(selection: $selectedTabIndex) {
//            HomeView()
//                .tabItem {
//                    Label("個人", systemImage: "house.fill")
//                }
//                .tag(0)
//
//            FridgeView()
//                .tabItem {
//                    Label("冰箱", systemImage: "refrigerator.fill")
////                .tabItem {
////                    VStack {
////                        Image("fridgeIcon")//TODO 這個之後可以換成點擊他會打開的圖
////                        Text("冰箱")
////                    }
//                }
//                .tag(1)
//
//            RecipeView(recipeManager: RecipeManager())
//                .tabItem {
//                    Label("食譜", systemImage: "books.vertical.fill")
//                }
//                .tag(2)
//
//            GroceryListView()  // 這裡你可以替換為針對「採買」專用的視圖組件
//                .tabItem {
//                    Label("採買", systemImage: "storefront.fill")
//                }
//                .tag(3)
//        }
//        .tint(Color("NavigationBarTitle"))
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}

//import SwiftUI
//
//struct MainView: View {
//
//    @State private var selectedTabIndex = 0
//    @State private var iconScale: [CGFloat] = [1.0, 1.0, 1.0]
//
//    var body: some View {
//        TabView(selection: $selectedTabIndex) {
//            RecommendRecipeListView()
//                .tabItem {
//                    VStack {
//                        Image("fridgeIcon")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 24, height: 24)
//                            .scaleEffect(iconScale[0])
//                            .onTapGesture {
//                                // 可以在這裡執行更多自定義行為
//                                animateIcon(at: 0)
//                            }
//                        Text("Fridge")
//                    }
//                }
//                .tag(0)
//            RecommendRecipeListView()
//                .tabItem {
//                    VStack {
//                        Image("fridgeIcon")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 24, height: 24)
//                            .scaleEffect(iconScale[0])
//                            .onTapGesture {
//                                // 可以在這裡執行更多自定義行為
//                                animateIcon(at: 0)
//                            }
//                        Text("Fridge")
//                    }
//                }
//                .tag(1)
//            RecommendRecipeListView()
//                .tabItem {
//                    VStack {
//                        Image("fridgeIcon")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 24, height: 24)
//                            .scaleEffect(iconScale[0])
//                            .onTapGesture {
//                                // 可以在這裡執行更多自定義行為
//                                animateIcon(at: 0)
//                            }
//                        Text("Fridge")
//                    }
//                }
//                .tag(2)
//            RecommendRecipeListView()
//                .tabItem {
//                    VStack {
//                        Image("fridgeIcon")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 24, height: 24)
//                            .scaleEffect(iconScale[0])
//                            .onTapGesture {
//                                // 可以在這裡執行更多自定義行為
//                                animateIcon(at: 0)
//                            }
//                        Text("Fridge")
//                    }
//                }
//                .tag(3)
//        }
//        .tint(Color("NavigationBarTitle"))
//    }
//    func animateIcon(at index: Int) {
//        withAnimation(.easeInOut(duration: 0.2)) {
//            iconScale[index] = 1.2  // 放大
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            withAnimation(.easeInOut(duration: 0.2)) {
//                iconScale[index] = 1.0  // 恢復原狀
//            }
//        }
//    }
//}
//
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//    }
//}
