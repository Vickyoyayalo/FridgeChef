//
//  MainView.swift
//  FoodPin
//
//  Created by Simon Ng on 17/10/2023.
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTabIndex = 0
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            RecommendRecipeListView()
                .tabItem {
                    Label("個人", systemImage: "house.circle.fill")
                }
                .tag(0)
            
            FridgeView()  // 這裡你可以替換為針對「冰箱」專用的視圖組件
                .tabItem {
                    VStack {
                        Image("fridgeIcon")//TODO 這個之後可以換成點擊他會打開的圖
                        Text("冰箱")
                    }
                }
                .tag(1)
            
            RecipeView(recipeManager: RecipeManager())
                .tabItem {
                    Label("食譜", systemImage: "books.vertical.circle")
                }
                .tag(2)
            
            GroceryListView()  // 這裡你可以替換為針對「採買」專用的視圖組件
                .tabItem {
                    Label("採買", systemImage: "storefront.circle.fill")
                }
                .tag(3)
        }
        .tint(Color("NavigationBarTitle"))
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

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
