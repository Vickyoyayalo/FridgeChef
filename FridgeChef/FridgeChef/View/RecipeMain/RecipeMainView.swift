//
//  RecipeMainView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.

import SwiftUI

struct RecipeMainView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var showingAddGroceryForm = false
    @State private var searchQuery: String = ""
    @State private var isShowingDefaultPage = true
    @State private var selectedRecipe: Recipe? = nil // Add this state for navigation
    var showEditAndAddButtons: Bool = false

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
                                RecipeRowView(recipe: recipe, toggleFavorite: {
                                    viewModel.toggleFavorite(for: recipe.id)
                                }, viewModel: RecipeSearchViewModel())
                                .onTapGesture {
                                    selectedRecipe = recipe // Set selected recipe when tapped
                                }
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
                            Text("Opps...Let's try again.. \nSearch by keywords🕵🏻‍♂️") //請輸入關鍵字搜尋食譜
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                .navigationTitle("Recipe 👩🏻‍🍳")
                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
                .onSubmit(of: .search) {
                    if !searchQuery.isEmpty {
                        isShowingDefaultPage = false
                        viewModel.searchRecipes(query: searchQuery)
                    } else {
                        isShowingDefaultPage = true
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
            .navigationBarItems(
                leading: showEditAndAddButtons ? EditButton().bold() : nil,
                trailing: showEditAndAddButtons ? addButton : nil
            )
            .background(
                NavigationLink(
                    destination: selectedRecipe.map { RecipeDetailView(recipeId: $0.id) },
                    isActive: Binding(
                        get: { selectedRecipe != nil },
                        set: { if !$0 { selectedRecipe = nil } }
                    ),
                    label: { EmptyView() } // Empty view for programmatic navigation
                )
            )
        }
    }

    var addButton: some View {
        Button(action: {
            showingAddGroceryForm = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
    }
}

struct RecipeMainView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeMainView()
            .environmentObject(RecipeSearchViewModel())
    }
}

//import SwiftUI
//
//struct RecipeMainView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var showingAddGroceryForm = false
//    @State private var searchQuery: String = ""
//    @State private var isShowingDefaultPage = true
//    @State private var selectedRecipe: Recipe? = nil // Add this state for navigation
//    
//    var showEditAndAddButtons: Bool = false
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
//                            .onReceive(NotificationCenter.default.publisher(for: .performSearch)) { notification in
//                                if let keyword = notification.object as? String {
//                                    searchQuery = keyword
//                                    performSearch()
//                                }
//                            }
//                    } else {
//                        if viewModel.isLoading {
//                            Spacer()
//                            ProgressView()
//                                .scaleEffect(1.5)
//                            Spacer()
//                        } else if !viewModel.recipes.isEmpty {
//                            // 有食谱时显示食谱列表
//                            List(viewModel.recipes, id: \.id) { recipe in
//                                RecipeRowView(recipe: recipe, toggleFavorite: {
//                                    viewModel.toggleFavorite(for: recipe.id)
//                                }, viewModel: RecipeSearchViewModel())
//                                .onTapGesture {
//                                    selectedRecipe = recipe // Set selected recipe when tapped
//                                }
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                            }
//                            .listStyle(PlainListStyle())
//                        } else if let errorMessage = viewModel.errorMessage {
//                            // 显示错误消息
//                            Spacer()
//                            Text("錯誤：\(errorMessage.message)")
//                                .foregroundColor(.red)
//                                .padding()
//                            Spacer()
//                        } else {
//                            // 提示输入搜索关键字
//                            Spacer()
//                            Text("Oops... Let's try again..\nSearch by keywords🕵🏻‍♂️") //請輸入關鍵字搜尋食譜
//                                .foregroundColor(.gray)
//                            Spacer()
//                        }
//                    }
//                }
//                .navigationTitle("Recipe 👩🏻‍🍳")
//                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
//                .onSubmit(of: .search) {
//                    performSearch()
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
//            .navigationBarItems(
//                leading: showEditAndAddButtons ? EditButton().bold() : nil,
//                trailing: showEditAndAddButtons ? addButton : nil
//            )
//            .background(
//                NavigationLink(
//                    destination: selectedRecipe.map { RecipeDetailView(recipeId: $0.id) },
//                    isActive: Binding(
//                        get: { selectedRecipe != nil },
//                        set: { if !$0 { selectedRecipe = nil } }
//                    ),
//                    label: { EmptyView() } // Empty view for programmatic navigation
//                )
//            )
//        }
//        .onAppear {
//            // 設置默認頁面
//            isShowingDefaultPage = viewModel.recipes.isEmpty
//        }
//    }
//    
//    var addButton: some View {
//        Button(action: {
//            showingAddGroceryForm = true
//        }) {
//            Image(systemName: "plus")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//    
//    private func performSearch() {
//        if !searchQuery.isEmpty {
//            isShowingDefaultPage = false
//            viewModel.searchRecipes(query: searchQuery)
//        } else {
//            isShowingDefaultPage = true
//        }
//    }
//}
//
//struct RecipeMainView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeMainView()
//            .environmentObject(RecipeSearchViewModel())
//    }
//}
//
//// 定義一個通知名稱
//extension Notification.Name {
//    static let performSearch = Notification.Name("performSearch")
//}


//import SwiftUI
//
//struct RecipeMainView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @State private var showingAddGroceryForm = false
//    @State private var searchQuery: String = "" {
//        didSet {
//            // 當搜尋欄清空時，清空 recipes 並顯示 DefaultRecipeView
//            if searchQuery.isEmpty {
//                isShowingDefaultPage = true
//                viewModel.recipes.removeAll() // 清空搜尋結果
//            }
//        }
//    }
//    @State private var isShowingDefaultPage = true
//    @State private var selectedRecipe: Recipe? = nil
//    
//    var showEditAndAddButtons: Bool = false
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // 背景漸變
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
//                        // 顯示預設 DefaultRecipeView 頁面
//                        DefaultRecipeView(recipeManager: RecipeManager())
//                    } else {
//                        if viewModel.isLoading {
//                            Spacer()
//                            ProgressView()
//                                .scaleEffect(1.5)
//                            Spacer()
//                        } else if !viewModel.recipes.isEmpty {
//                            // 顯示搜尋結果列表
//                            List(viewModel.recipes, id: \.id) { recipe in
//                                RecipeRowView(recipe: recipe, toggleFavorite: {
//                                    viewModel.toggleFavorite(for: recipe.id)
//                                }, viewModel: RecipeSearchViewModel())
//                                .onTapGesture {
//                                    selectedRecipe = recipe // 當點擊時選擇食譜
//                                }
//                                .listRowBackground(Color.clear)
//                                .listRowSeparator(.hidden)
//                            }
//                            .listStyle(PlainListStyle())
//                        } else if let errorMessage = viewModel.errorMessage {
//                            // 顯示錯誤消息
//                            Spacer()
//                            Text("錯誤：\(errorMessage.message)")
//                                .foregroundColor(.red)
//                                .padding()
//                            Spacer()
//                        } else {
//                            // 搜尋無結果時的提示
//                            Spacer()
//                            Text("Oops... Let's try again..\nSearch by keywords🕵🏻‍♂️")
//                                .foregroundColor(.gray)
//                            Spacer()
//                        }
//                    }
//                }
//                .navigationTitle("Recipe 👩🏻‍🍳")
//                .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search recipes")
//                .onSubmit(of: .search) {
//                    performSearch()
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
//            .navigationBarItems(
//                leading: showEditAndAddButtons ? EditButton().bold() : nil,
//                trailing: showEditAndAddButtons ? addButton : nil
//            )
//            .background(
//                NavigationLink(
//                    destination: selectedRecipe.map { RecipeDetailView(recipeId: $0.id) },
//                    isActive: Binding(
//                        get: { selectedRecipe != nil },
//                        set: { if !$0 { selectedRecipe = nil } }
//                    ),
//                    label: { EmptyView() } // 空視圖以進行程式導向導航
//                )
//            )
//        }
//        .onAppear {
//            // 設置默認頁面
//            isShowingDefaultPage = viewModel.recipes.isEmpty
//        }
//    }
//    
//    var addButton: some View {
//        Button(action: {
//            showingAddGroceryForm = true
//        }) {
//            Image(systemName: "plus")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//    
//    private func performSearch() {
//        if !searchQuery.isEmpty {
//            isShowingDefaultPage = false
//            viewModel.searchRecipes(query: searchQuery)
//        } else {
//            isShowingDefaultPage = true
//            viewModel.recipes.removeAll() // 清空結果
//        }
//    }
//}
//
//struct RecipeMainView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeMainView()
//            .environmentObject(RecipeSearchViewModel())
//    }
//}
//
//// 定義一個通知名稱
//extension Notification.Name {
//    static let performSearch = Notification.Name("performSearch")
//}
