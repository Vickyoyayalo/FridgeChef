//
//  RecipeMainView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//

import SwiftUI

struct RecipeMainView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var showingAddGroceryForm = false
    @State private var searchQuery: String = ""
    @State private var isShowingDefaultPage = true // 用于控制默认页面的显示状态
    var showEditAndAddButtons: Bool = false // 用來控制是否顯示按鈕
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if isShowingDefaultPage {
                        // 显示默认 SampleRecipeView 页面
                        DefaultRecipeView(recipeManager: RecipeManager())
                    } else {
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
                                    }, viewModel: RecipeSearchViewModel())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .listStyle(PlainListStyle())
                        } else if let errorMessage = viewModel.errorMessage {
                            // 显示错误消息
                            Spacer()
                            Text("wrong：\(errorMessage.message)")
                                .foregroundColor(.red)
                                .padding()
                            Spacer()
                        } else {
                            // 提示输入搜索关键字
                            Spacer()
                            Text("Search by keywords🕵🏻‍♂️") //請輸入關鍵字搜尋食譜
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Recipe 👩🏻‍🍳")
                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
                .onSubmit(of: .search) {
                    if !searchQuery.isEmpty {
                        isShowingDefaultPage = false // 如果搜索了，隐藏默认页面
                        viewModel.searchRecipes(query: searchQuery)
                    } else {
                        isShowingDefaultPage = true // 搜索为空时，显示默认页面
                    }
                }
                .alert(item: $viewModel.errorMessage) { errorMessage in
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage.message),
                        dismissButton: .default(Text("Sure")) {
                            viewModel.errorMessage = nil
                        }
                    )
                }
                .sheet(isPresented: $showingAddGroceryForm) {
                    AddGroceryForm(viewModel: AddGroceryFormViewModel())
                }
            }
            // 根據 showEditAndAddButtons 判斷是否顯示按鈕
            .navigationBarItems(
                leading: showEditAndAddButtons ? EditButton().bold() : nil,
                trailing: showEditAndAddButtons ? addButton : nil
            )
        }
    }
    
    var addButton: some View {
        Button(action: {
            // 点击添加按钮时设置为新增模式
            showingAddGroceryForm = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
    }
}

//import SwiftUI
//
//struct RecipeMainView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var showingAddGroceryForm = false
//    @State private var searchQuery: String = ""
//    @State private var isShowingDefaultPage = true // 用于控制默认页面的显示状态
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // 背景渐变
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                
//                VStack {
//                    if isShowingDefaultPage {
//                        // 显示默认 SampleRecipeView 页面
//                        DefaultRecipeView(recipeManager: RecipeManager())
//                    } else {
//                        if viewModel.isLoading {
//                            Spacer()
//                            ProgressView()
//                                .scaleEffect(1.5)
//                            Spacer()
//                        } else if !viewModel.recipes.isEmpty {
//                            // 有食谱时显示食谱列表
//                            List(viewModel.recipes, id: \.id) { recipe in
//                                NavigationLink(destination: RecipeDetailView(recipeId: recipe.id)) {
//                                    RecipeRowView(recipe: recipe, toggleFavorite: {
//                                        viewModel.toggleFavorite(for: recipe.id)
//                                    }, viewModel: RecipeSearchViewModel())
//                                }
//                                .buttonStyle(PlainButtonStyle())
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                            }
//                            .listStyle(PlainListStyle())
//                        } else if let errorMessage = viewModel.errorMessage {
//                            // 显示错误消息
//                            Spacer()
//                            Text("wrong：\(errorMessage.message)")
//                                .foregroundColor(.red)
//                                .padding()
//                            Spacer()
//                        } else {
//                            // 提示输入搜索关键字
//                            Spacer()
//                            Text("Search by keywords🕵🏻‍♂️") //請輸入關鍵字搜尋食譜
//                                .foregroundColor(.gray)
//                            Spacer()
//                        }
//                    }
//                }
//                .navigationTitle("Recipe 👩🏻‍🍳")
//                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
//                .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
//                .onSubmit(of: .search) {
//                    if !searchQuery.isEmpty {
//                        isShowingDefaultPage = false // 如果搜索了，隐藏默认页面
//                        viewModel.searchRecipes(query: searchQuery)
//                    } else {
//                        isShowingDefaultPage = true // 搜索为空时，显示默认页面
//                    }
//                }
//                .alert(item: $viewModel.errorMessage) { errorMessage in
//                    Alert(
//                        title: Text("Error"),
//                        message: Text(errorMessage.message),
//                        dismissButton: .default(Text("Sure")) {
//                            viewModel.errorMessage = nil
//                        }
//                    )
//                }
//                .sheet(isPresented: $showingAddGroceryForm) {
//                    AddGroceryForm(viewModel: AddGroceryFormViewModel())
//                }
//            }
//        }
//    }
//    
//    var addButton: some View {
//        Button(action: {
//            // 点击添加按钮时设置为新增模式
//            showingAddGroceryForm = true
//        }) {
//            Image(systemName: "plus")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//}
