//
//  RecipeDetailView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI
import IQKeyboardManagerSwift

struct RecipeDetailView: View {
    let recipeId: Int
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var inputServings: String = ""
    @State private var animate = false // 用于动画
    @State private var ratingScore: Int = 5
    @State private var commentUser: String = ""
    @State private var commentText: String = ""
    
    // 定義主要色調
    let primaryColor = Color(UIColor(named: "NavigationBarTitle") ?? .orange)
    let secondaryColor = Color.white
    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)
    
    var body: some View {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 确保 selectedRecipe 不为 nil
                        if let recipe = viewModel.selectedRecipe {
                            ZStack(alignment: .topTrailing) {
                                if let imageUrl = recipe.image {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 250)
                                            .cornerRadius(15)
                                            .shadow(radius: 10)
                                    } placeholder: {
                                        ProgressView()
                                            .frame(height: 250)
                                    }
                                } else {
                                    Image(systemName: "RecipeFood")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 250)
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                        .foregroundColor(.gray)
                                        .background(Color(.systemGray6))
                                }

                                // 收藏按钮
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.toggleFavorite(for: recipeId)
                                        animate = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        animate = false
                                    }
                                }) {
                                    Image(systemName: (recipe.isFavorite ?? false) ? "heart.fill" : "heart")
                                        .foregroundColor((recipe.isFavorite ?? false) ? Color.red : Color.gray)
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                        .scaleEffect(animate ? 1.5 : 1.0)
                                        .opacity(animate ? 0.5 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: animate)
                                }
                            }
                            .frame(height: 250)

                            // 食谱标题
                            Text(recipe.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.orange)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)
                        
                        // 基本資訊
                        HStack {
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                            Spacer()
                            Label("\(recipe.readyInMinutes) Minutes", systemImage: "clock")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        // 調整份量
                        SectionView(title: "Decide your serving size") {
                            HStack {
                                TextField("Serving Size", text: $inputServings, onCommit: {
                                    updateServings()
                                })
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button(action: {
                                    updateServings()
                                }) {
                                    Text("🔍 Go")
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(primaryColor)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // 菜系、类型和饮食
                        if !recipe.cuisines.isEmpty || !recipe.dishTypes.isEmpty || !recipe.diets.isEmpty {
                            SectionView(title: "Category") {
                                VStack(alignment: .leading, spacing: 5) { // 减少间距
                                    if !recipe.cuisines.isEmpty {
                                        CategorySectionView(title: "• Cuisines", items: recipe.cuisines)
                                    }
                                    if !recipe.dishTypes.isEmpty {
                                        CategorySectionView(title: "• Dishtypes", items: recipe.dishTypes)
                                    }
                                    if !recipe.diets.isEmpty {
                                        CategorySectionView(title: "• Diets", items: recipe.diets)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                        }
                        // 食材
                        SectionView(title: "Ingredients") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(recipe.extendedIngredients) { ingredient in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .font(.title2)
                                            .foregroundColor(primaryColor)
                                        Text("\(String(format: "%.2f", ingredient.amount)) \(ingredient.unit) \(ingredient.name)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading) // 确保文本框的对齐
                                    }
                                }
                            }
                            .padding(.horizontal) // 添加水平内边距
                            .padding(.vertical, 1) // 根据需要调整垂直间距
                        }
                        
                        // 步驟
                        SectionView(title: "Instructions") {
                            if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                                ForEach(analyzedInstructions) { instruction in
                                    VStack(alignment: .leading, spacing: 10) {
                                        if !instruction.name.isEmpty {
                                            Text(instruction.name)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(primaryColor)
                                        }
                                        
                                        ForEach(instruction.steps, id: \.number) { step in
                                            StepView(step: step)
                                        }
                                    }
                                    .padding(.bottom, 10)
                                    .padding(.horizontal)
                                }
                            } else if let instructions = recipe.instructions?.htmlDecoded(), !instructions.isEmpty {
                                Text(instructions)
                                    .font(.body)
                                    .padding(.horizontal)
                            } else {
                                Text("No Instructions")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.orange.opacity(0.3))
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.getRecipeDetails(recipeId: recipeId)
            }
            .navigationBarTitle("Recipe Details", displayMode: .inline)
            // 添加 alert 來顯示錯誤訊息
            .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage.message),
                    dismissButton: .default(Text("Sure")) {
                        viewModel.errorMessage = nil
                    }
                )
            }
        }
    }
    
    // 將更新份量的邏輯提取出來
    private func updateServings() {
        if let newServings = Int(inputServings), newServings > 0 {
            viewModel.adjustServings(newServings: newServings)
        } else {
            viewModel.errorMessage = ErrorMessage(message: "請輸入有效的份量。")
        }
    }
}

// 新增一個 CategorySectionView，用於顯示分類項目
struct CategorySectionView: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { // 修改間距為8
                    ForEach(items, id: \.self) { item in
                        TagView(text: item)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 0) // 減少左右 padding
    }
}

// 定義一個 TagView，用於顯示每個項目
struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
            .foregroundColor(.white)
            .fontWeight(.medium)
            .cornerRadius(8)
    }
}

// 預覽
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipeId: 1)
            .environmentObject(RecipeSearchViewModel())
    }
}
