////
////  CategoryView.swift
////  FridgeChef
////
////  Created by Vickyhereiam on 2024/10/6.
////
//
//import SwiftUI
//
//struct CategoryView: View {
//    let category: String
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    
//    var body: some View {
//        VStack {
//            // 顯示所選分類的標題
//            Text(category)
//                .font(.custom("ArialRoundedMTBold", size: 25))
//                .fontWeight(.semibold)
//                .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
//                .padding(.horizontal, 16)
//            
//            if viewModel.isLoading {
//                Spacer()
//                ProgressView()
//                    .scaleEffect(1.5)
//                Spacer()
//            } else if !viewModel.recipes.isEmpty {
//                // 顯示分類下的食譜列表
//                List(viewModel.recipes, id: \.id) { recipe in
//                    RecipeRowView(recipe: recipe, toggleFavorite: {
//                        viewModel.toggleFavorite(for: recipe.id)
//                    }, viewModel: RecipeSearchViewModel())
//                    .onTapGesture {
//                        // 導航到食譜詳情頁面
//                        viewModel.selectedRecipe = RecipeDetails(id: recipe.id, title: recipe.title, image: recipe.image, servings: recipe.servings, readyInMinutes: recipe.readyInMinutes, sourceUrl: nil, summary: recipe.summary, cuisines: [], dishTypes: recipe.dishTypes, diets: [], instructions: nil, extendedIngredients: [], analyzedInstructions: nil, isFavorite: recipe.isFavorite)
//                    }
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//                .listStyle(PlainListStyle())
//            } else if let errorMessage = viewModel.errorMessage {
//                // 顯示錯誤消息
//                Spacer()
//                Text("Category Wrong message：\(errorMessage.message)")
//                    .foregroundColor(.red)
//                    .padding()
//                Spacer()
//            } else {
//                // 提示無相關食譜
//                Spacer()
//                Text("We are on the way ...")
//                    .foregroundColor(.gray)
//                Spacer()
//            }
//        }
//        .navigationTitle("\(category) Recipe")
//        .onAppear {
//            // 根據分類搜索食譜
//            viewModel.searchRecipesByCategory(category: category)
//        }
//        .alert(item: $viewModel.errorMessage) { errorMessage in
//            Alert(
//                title: Text("錯誤"),
//                message: Text(errorMessage.message),
//                dismissButton: .default(Text("確定")) {
//                    viewModel.errorMessage = nil
//                }
//            )
//        }
//    }
//}
//
//struct CategoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryView(category: "Breakfast")
//            .environmentObject(RecipeSearchViewModel())
//    }
//}
//
