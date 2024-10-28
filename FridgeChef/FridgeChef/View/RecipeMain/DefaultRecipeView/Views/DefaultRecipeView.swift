//
//  DefaultRecipeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.
//

import SwiftUI

struct DefaultRecipeView: View {
    @ObservedObject var recipeManager: RecipeManager
    @State var selectedRecipe: DefaultRecipe? = nil
    @State private var moveUp = false
    
    var body: some View {
        //        NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                // 1. 視覺吸引力
                VStack {
                    ZStack {
                        Image("discomonster3") // 替換為你的插圖名稱
                            .resizable()
                            .scaledToFill()
                            .frame(height: 400)
                            .shadow(radius: 10)
                        // 使用 @State 變數控制水平偏移
                            .offset(y: moveUp ? -50 : 50)
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true),
                                value: moveUp
                            )
                            .onAppear {
                                // 啟動動畫
                                moveUp = true
                                
                            }
                    }
                    
                    Text("Looking for inspiration? \nEnter a keyword to get started!")
                        .font(.custom("Menlo-BoldItalic", size: 17))
                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange))
                        .fontWeight(.bold)
                        .padding(.top, 15)
                        .shadow(radius: 10)
                }
                .padding(.horizontal, 16) // 統一的水平內邊距
            }
//            VStack {
//                ForEach(recipeManager.recipes) { recipe in
//                    DefaultRecipeCard(recipe: recipe)
//                        .onTapGesture {
//                            selectedRecipe = recipe
//                        }
//                }
//                .padding(.horizontal)
//            }
//            .padding(.vertical)
//                .fullScreenCover(item: $selectedRecipe) { recipe in
//                    DefaultRecipeDetailView(recipe: recipe)
//
//                }
            }
        .scrollIndicators(.hidden)
//            .background(.ultraThinMaterial)
//            .navigationTitle("Recipes")
        }
    }
//}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultRecipeView(recipeManager: RecipeManager())
            .preferredColorScheme(.light)
    }
}
//
//import SwiftUI
//
//struct DefaultRecipeView: View {
//    let recipeManager: RecipeManager
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                // 1. 視覺吸引力
//                VStack {
//                    Image("himonster") // 替換為你的插圖名稱
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 200)
//                        .shadow(radius: 10)
//                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
//                    
//                    Text("Looking for inspiration? \nEnter a keyword to get started!")
//                        .font(.custom("Menlo-BoldItalic", size: 15))
//                        .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange))
//                        .fontWeight(.bold)
//                        .padding(.top, 10)
//                        .shadow(radius: 10)
//                }
//                .padding(.horizontal, 16) // 統一的水平內邊距
//                
//                // 2. 提供導航建議
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Recommend")
//                        .font(.custom("ArialRoundedMTBold", size: 25))
//                        .fontWeight(.semibold)
//                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                        .padding(.horizontal, 16) // 對齊標題與內容
//                    
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 16) {
//                            ForEach(recipeManager.recommendedRecipes) { recipe in
//                                NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
//                                    RecipeCardView(recipe: recipe)
//                                }
//                                .buttonStyle(PlainButtonStyle())
//                            }
//                        }
//                        .padding(.horizontal, 16) // 保持卡片與標題對齊
//                    }
//                }
//
//                // 3. 類別導航
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Category")
//                        .font(.custom("ArialRoundedMTBold", size: 25))
//                        .fontWeight(.semibold)
//                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                        .padding(.horizontal, 16)
//                    
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 16) {
//                            ForEach(recipeManager.categories, id: \.self) { category in
//                                NavigationLink(destination: CategoryView(category: category)) {
//                                    CategoryIconView(category: category)
//                                }
//                                .buttonStyle(PlainButtonStyle())
//                            }
//                        }
//                        .padding(.horizontal, 16) // 保持水平對齊
//                    }
//                }
//
//                // 4. 熱門搜索
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Popular Searches")
//                        .font(.custom("ArialRoundedMTBold", size: 25))
//                        .fontWeight(.semibold)
//                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                        .padding(.horizontal, 16) // 保持標題與內容對齊
//                    
//                    FlowLayout(mode: .scrollable, items: recipeManager.popularSearches) { keyword in
//                        Button(action: {
//                            // 觸發搜索
//                            NotificationCenter.default.post(name: .performSearch, object: keyword)
//                        }) {
//                            Text(keyword)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 8)
//                                .background(Color.orange.opacity(0.2))
//                                .foregroundColor(.orange)
//                                .cornerRadius(20)
//                        }
//                    }
//                    .padding(.horizontal, 16) // 保持搜索按鈕與標題對齊
//                }
//
//                // 5. 搜索記錄展示
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Searching Records")
//                        .font(.custom("ArialRoundedMTBold", size: 25))
//                        .fontWeight(.semibold)
//                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                        .padding(.horizontal, 16) // 保持標題與內容對齊
//                    
//                    FlowLayout(mode: .scrollable, items: recipeManager.popularSearches) { keyword in
//                        Button(action: {
//                            // 觸發搜索
//                            NotificationCenter.default.post(name: .performSearch, object: keyword)
//                        }) {
//                            Text(keyword)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 8)
//                                .background(Color.orange.opacity(0.2))
//                                .foregroundColor(.orange)
//                                .cornerRadius(20)
//                        }
//                    }
//                    .padding(.horizontal, 16) // 保持搜索按鈕與標題對齊
//                }
//
//                Spacer()
//            }
//            .padding(.top)
//        }
//        .background(
//            Image("Launchmonster") // 替換為你的背景圖名稱
//                .resizable()
//                .scaledToFill()
//                .opacity(0.1)
//        )
//    }
//}
//
//struct DefaultRecipeView_Previews: PreviewProvider {
//    static var previews: some View {
//        DefaultRecipeView(recipeManager: RecipeManager())
//    }
//}
