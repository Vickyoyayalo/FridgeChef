//
//  RecipeMainView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

//import SwiftUI
//
//struct RecipeMainView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var searchQuery: String = ""
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                // 搜索按鈕
//                Button(action: {
//                    viewModel.searchRecipes(query: searchQuery)
//                }) {
//                    Text("搜尋食譜")
//                        .bold()
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]), startPoint: .leading, endPoint: .trailing))
//                        .cornerRadius(10)
//                }
//                .padding([.horizontal, .bottom])
//
//                // 食譜列表
//                if viewModel.isLoading {
//                    Spacer()
//                    ProgressView()
//                        .scaleEffect(1.5)
//                    Spacer()
//                } else if !viewModel.recipes.isEmpty {
//                    List(viewModel.recipes, id: \.id) { recipe in
//                        NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
//                            RecipeRowView(recipe: recipe, toggleFavorite: {
//                                viewModel.toggleFavorite(for: recipe.id)
//                            })
//                        }
//                        .buttonStyle(PlainButtonStyle()) // 移除按钮的默认样式
//                        .listRowBackground(Color.clear)  // 设置透明背景
//                    }
//                    .listStyle(PlainListStyle()) // 使用简洁的列表风格
//
//                } else if let errorMessage = viewModel.errorMessage {
//                    Spacer()
//                    Text("錯誤：\(errorMessage.message)")
//                        .foregroundColor(.red)
//                        .padding()
//                    Spacer()
//                } else {
//                    Spacer()
//                    Text("請輸入關鍵字搜尋食譜")
//                        .foregroundColor(.gray)
//                    Spacer()
//                }
//            }
//            .background(.ultraThinMaterial)
//            .navigationTitle("Recipe 👩🏻‍🍳 ")
//            .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Recipes")
//
//            .alert(item: $viewModel.errorMessage) { errorMessage in
//                Alert(
//                    title: Text("錯誤"),
//                    message: Text(errorMessage.message),
//                    dismissButton: .default(Text("確定")) {
//                        viewModel.errorMessage = nil
//                    }
//                )
//            }
//        }
//    }
//}
//
import SwiftUI

struct RecipeMainView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var searchQuery: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 漸層背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                VStack {
                    // 如果正在加载显示进度指示器
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if !viewModel.recipes.isEmpty {
                        // 有食谱时显示食谱列表
                        List(viewModel.recipes, id: \.id) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
                                RecipeRowView(recipe: recipe, toggleFavorite: {
                                    viewModel.toggleFavorite(for: recipe.id)
                                })
                            }
                            .buttonStyle(PlainButtonStyle()) // 移除按钮的默认样式
                            .listRowBackground(Color.clear)  // 设置透明背景
                        }
                        .listStyle(PlainListStyle()) // 使用简洁的列表风格
                    } else if let errorMessage = viewModel.errorMessage {
                        // 显示错误消息
                        Spacer()
                        Text("错误：\(errorMessage.message)")
                            .foregroundColor(.red)
                            .padding()
                        Spacer()
                    } else {
                        // 提示输入搜索关键字
                        Spacer()
                        Text("請輸入關鍵字搜尋食譜")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                .navigationTitle("Recipe 👩🏻‍🍳")
                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Recipes")
                .onSubmit(of: .search) {
                    viewModel.searchRecipes(query: searchQuery)
                }
                .alert(item: $viewModel.errorMessage) { errorMessage in
                    Alert(
                        title: Text("错误"),
                        message: Text(errorMessage.message),
                        dismissButton: .default(Text("确定")) {
                            viewModel.errorMessage = nil
                        }
                    )
                }
            }
        }
    }
}
