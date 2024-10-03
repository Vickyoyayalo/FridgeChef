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
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var inputServings: String = ""
    @State private var animate = false
    @State private var ratingScore: Int = 5
    @State private var commentUser: String = ""
    @State private var commentText: String = ""
    
    // 定義主要色調
    let primaryColor = Color(UIColor(named: "NavigationBarTitle") ?? .orange)
    let secondaryColor = Color.white
    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)
    
    // 新增的狀態變量來管理警告
    @State private var activeAlert: ActiveAlert?
    @State private var showAddedLabel = false // 用於顯示「Food added」提示
    
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
                                        .padding([.leading, .trailing, .bottom], 15) // 添加左右和底部的 padding
                                        .padding(.top, 30) // 增加圖片與頂部的距離
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
                                    .background(Color.white.opacity(0.6))
                                    .padding([.leading, .trailing, .bottom], 15)
                                    .padding(.top, 20)
                            }
                            
                            // 收藏按钮调整位置
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
                                    .padding(10) // 调整 padding
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                                    .scaleEffect(animate ? 1.5 : 1.0)
                                    .opacity(animate ? 0.5 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: animate)
                            }
                            .padding(.top, 40) // 調整與頂部的距離
                            .padding(.trailing, 25) // 調整與右側的距離
                        }
                        .frame(height: 250)
                        
                        // 食谱标题
                        Text(recipe.title)
                            .font(.custom("ArialRoundedMTBold", size: 25))
                            .foregroundColor(primaryColor.opacity(0.9))
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // 基本資訊
                        HStack {
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                            Spacer()
                            Label("\(recipe.readyInMinutes) Minutes", systemImage: "clock")
                        }
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        
                        // 調整份量
                        SectionView(title: "Decide your serving size") {
                            HStack {
                                TextField(" 🔍 Serving Size", text: $inputServings, onCommit: {
                                    updateServings()
                                })
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.custom("ArialRoundedMTBold", size: 18))
                                
                                Button(action: {
                                    updateServings()
                                }) {
                                    Text("Go")
                                        .bold()
                                        .foregroundColor(.white)
                                        .font(.custom("ArialRoundedMTBold", size: 18))
                                        .padding(5)
                                        .background(primaryColor)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading) {
                            if !recipe.cuisines.isEmpty || !recipe.dishTypes.isEmpty || !recipe.diets.isEmpty {
                                SectionView(title: "Category") {
                                    VStack(alignment: .leading, spacing: 10) { // 增加間距以容納 TagViews
                                        if !recipe.cuisines.isEmpty {
                                            CategoryItemView(title: "Cuisines", items: recipe.cuisines, primaryColor: primaryColor)
                                        }
                                        if !recipe.dishTypes.isEmpty {
                                            CategoryItemView(title: "Dish Types", items: recipe.dishTypes, primaryColor: primaryColor)
                                        }
                                        if !recipe.diets.isEmpty {
                                            CategoryItemView(title: "Diets", items: recipe.diets, primaryColor: primaryColor)
                                        }
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                            
                            let parsedIngredients = recipe.extendedIngredients.map { extIngredient in
                                ParsedIngredient(
                                    name: extIngredient.name.capitalized, // 每個單詞的首字母大寫
                                    quantity: String(format: "%.2f", extIngredient.amount), // 保留兩位小數
                                    unit: extIngredient.unit.isEmpty ? "unit" : extIngredient.unit
                                )
                            }

                            // 食材區域
                            SectionView(title: "Ingredients") {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(parsedIngredients, id: \.name) { ingredient in
                                        IngredientRow(ingredient: ingredient) { selectedIngredient in
                                            let success = addIngredientToShoppingList(selectedIngredient)
                                            if success {
                                                activeAlert = .ingredient("\(ingredient.name) added to your Grocery List!")
                                            } else {
                                                activeAlert = .ingredient("\(ingredient.name) is already in your Grocery List.")
                                            }
                                            return success // 確保返回 Bool 值
                                        }
                                        .environmentObject(foodItemStore)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 1)
                                .padding(.leading, 5)
                            }
                            
                            // 步驟
                            SectionView(title: "Instructions") {
                                if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                                    ForEach(analyzedInstructions) { instruction in
                                        VStack(alignment: .leading, spacing: 10) {
                                            if !instruction.name.isEmpty {
                                                Text(instruction.name)
                                                    .font(.custom("ArialRoundedMTBold", size: 18))
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
                                        .font(.custom("ArialRoundedMTBold", size: 18))
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
                        .background(.white.opacity(0.6))
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                    }
                }
                .onAppear {
                    viewModel.getRecipeDetails(recipeId: recipeId)
                }
                .navigationBarTitle("Recipe Details", displayMode: .inline)
                // 統一的 alert 修飾符
                .alert(item: $activeAlert) { activeAlert in
                    switch activeAlert {
                    case .error(let errorMessage):
                        return Alert(
                            title: Text("Error"),
                            message: Text(errorMessage.message),
                            dismissButton: .default(Text("Sure")) {
                                viewModel.errorMessage = nil
                            }
                        )
                    case .ingredient(let message):
                        return Alert(
                            title: Text("Added to your Grocery List!"),
                            message: Text(message),
                            dismissButton: .default(Text("Sure"))
                        )
                    }
                }
            }
        }
    }
    // 將更新份量的邏輯提取出來
    private func updateServings() {
        if let newServings = Int(inputServings), newServings > 0 {
            viewModel.adjustServings(newServings: newServings)
        } else {
            activeAlert = .error(ErrorMessage(message: "Please insert a correct number."))
        }
    }
    
    private func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let expirationDate = Calendar.current.date(byAdding: .day, value: 5, to: today) ?? today
        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
        
        // 直接將 String 轉換為 Double，並四捨五入到兩位小數
        let quantityDouble = (Double(ingredient.quantity) ?? 1.0).rounded(toPlaces: 2)
        
        let newFoodItem = FoodItem(
            id: UUID(), // 確保每個 FoodItem 有唯一的 ID
            name: ingredient.name.capitalized,
            quantity: quantityDouble, // 保留並限制為兩位小數
            unit: ingredient.unit.isEmpty ? "unit" : ingredient.unit,
            status: .toBuy,
            daysRemaining: daysRemaining,
            image: nil
        )
        
        if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
            foodItemStore.foodItems.append(newFoodItem)
            return true
        } else {
            return false
        }
    }
}

// 新增一個 CategoryItemView，用於顯示每個分類項目及其 TagViews
struct CategoryItemView: View {
    let title: String
    let items: [String]
    let primaryColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.custom("ArialRoundedMTBold", size: 16))
                .foregroundColor(primaryColor)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("\(title):")
                    .font(.custom("ArialRoundedMTBold", size: 16))
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            TagView(text: item)
                        }
                    }
                }
            }
        }
    }
}

// 新增一個 TagView，用於顯示每個項目
struct TagView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.custom("ArialRoundedMTBold", size: 15))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.6))
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
            .environmentObject(FoodItemStore()) // 確保環境對象被傳遞
    }
}






//import SwiftUI
//import IQKeyboardManagerSwift
//
//struct RecipeDetailView: View {
//    let recipeId: Int
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var inputServings: String = ""
//    @State private var animate = false
//    @State private var ratingScore: Int = 5
//    @State private var commentUser: String = ""
//    @State private var commentText: String = ""
//
//    // 定義主要色調
//    let primaryColor = Color(UIColor(named: "NavigationBarTitle") ?? .orange)
//    let secondaryColor = Color.white
//    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)
//
//    // 新增的狀態變量來管理警告
//    @State private var activeAlert: ActiveAlert?
//
//    var body: some View {
//        ZStack {
//            // 渐变背景
//            LinearGradient(
//                gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .opacity(0.3)
//            .edgesIgnoringSafeArea(.all)
//
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    if let recipe = viewModel.selectedRecipe {
//                        ZStack(alignment: .topTrailing) {
//                            if let imageUrl = recipe.image {
//                                AsyncImage(url: URL(string: imageUrl)) { image in
//                                    image
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(height: 250)
//                                        .cornerRadius(15)
//                                        .shadow(radius: 10)
//                                        .padding([.leading, .trailing, .bottom], 15) // 添加左右和底部的 padding
//                                        .padding(.top, 30) // 增加圖片與頂部的距離
//                                } placeholder: {
//                                    ProgressView()
//                                        .frame(height: 250)
//                                }
//                            } else {
//                                Image(systemName: "RecipeFood")
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(height: 250)
//                                    .cornerRadius(15)
//                                    .shadow(radius: 5)
//                                    .foregroundColor(.gray)
//                                    .background(Color.white.opacity(0.6))
//                                    .padding([.leading, .trailing, .bottom], 15)
//                                    .padding(.top, 20)
//                            }
//
//                            // 收藏按钮调整位置
//                            Button(action: {
//                                withAnimation(.easeInOut(duration: 0.3)) {
//                                    viewModel.toggleFavorite(for: recipeId)
//                                    animate = true
//                                }
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                                    animate = false
//                                }
//                            }) {
//                                Image(systemName: (recipe.isFavorite ?? false) ? "heart.fill" : "heart")
//                                    .foregroundColor((recipe.isFavorite ?? false) ? Color.red : Color.gray)
//                                    .padding(10) // 调整 padding
//                                    .background(Color.white.opacity(0.8))
//                                    .clipShape(Circle())
//                                    .shadow(radius: 5)
//                                    .scaleEffect(animate ? 1.5 : 1.0)
//                                    .opacity(animate ? 0.5 : 1.0)
//                                    .animation(.easeInOut(duration: 0.3), value: animate)
//                            }
//                            .padding(.top, 40) // 調整與頂部的距離
//                            .padding(.trailing, 25) // 調整與右側的距離
//                        }
//                        .frame(height: 250)
//
//                        // 食谱标题
//                        Text(recipe.title)
//                            .font(.custom("ArialRoundedMTBold", size: 25))
//                            .foregroundColor(primaryColor.opacity(0.9))
//                            .padding(.horizontal)
//                            .fixedSize(horizontal: false, vertical: true)
//
//                        // 基本資訊
//                        HStack {
//                            Label("\(recipe.servings) servings", systemImage: "person.2")
//                            Spacer()
//                            Label("\(recipe.readyInMinutes) Minutes", systemImage: "clock")
//                        }
//                        .font(.custom("ArialRoundedMTBold", size: 15))
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
//
//                        // 調整份量
//                        SectionView(title: "Decide your serving size") {
//                            HStack {
//                                TextField(" 🔍 Serving Size", text: $inputServings, onCommit: {
//                                    updateServings()
//                                })
//                                .keyboardType(.numberPad)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .font(.custom("ArialRoundedMTBold", size: 18))
//
//                                Button(action: {
//                                    updateServings()
//                                }) {
//                                    Text("Go")
//                                        .bold()
//                                        .foregroundColor(.white)
//                                        .font(.custom("ArialRoundedMTBold", size: 18))
//                                        .padding(5)
//                                        .background(primaryColor)
//                                        .cornerRadius(8)
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//
//                        VStack(alignment: .leading) {
//                            if !recipe.cuisines.isEmpty || !recipe.dishTypes.isEmpty || !recipe.diets.isEmpty {
//                                SectionView(title: "Category") {
//                                    VStack(alignment: .leading, spacing: 10) { // 增加間距以容納 TagViews
//                                        if !recipe.cuisines.isEmpty {
//                                            CategoryItemView(title: "Cuisines", items: recipe.cuisines, primaryColor: primaryColor)
//                                        }
//                                        if !recipe.dishTypes.isEmpty {
//                                            CategoryItemView(title: "Dish Types", items: recipe.dishTypes, primaryColor: primaryColor)
//                                        }
//                                        if !recipe.diets.isEmpty {
//                                            CategoryItemView(title: "Diets", items: recipe.diets, primaryColor: primaryColor)
//                                        }
//                                    }
//                                    .padding(.leading, 20)
//                                }
//                            }
//
//                            let parsedIngredients = recipe.extendedIngredients.map { extIngredient in
//                                ParsedIngredient(
//                                    name: extIngredient.name.capitalized, // 每個單詞的首字母大寫
//                                    quantity: String(extIngredient.amount),
//                                    unit: extIngredient.unit.isEmpty ? "unit" : extIngredient.unit
//                                )
//                            }
//                            // 食材區域
//                            // 食材區域
//                            SectionView(title: "Ingredients") {
//                                VStack(alignment: .leading, spacing: 10) {
//                                    ForEach(parsedIngredients, id: \.name) { ingredient in
//                                        IngredientRow(ingredient: ingredient) { selectedIngredient in
//                                            let success = addIngredientToShoppingList(selectedIngredient)
//                                            if success {
//                                                activeAlert = .ingredient("\(ingredient.name) already in your Grocery List!")
//                                            } else {
//                                                activeAlert = .ingredient("\(ingredient.name) already saved in your Grocery List.")
//                                            }
//                                            return success // 確保返回 Bool 值
//                                        }
//                                        .environmentObject(foodItemStore)
//                                    }
//                                }
//                                .padding(.horizontal)
//                                .padding(.vertical, 1)
//                                .padding(.leading, 5)
//                            }
//
//                            // 步驟
//                            SectionView(title: "Instructions") {
//                                if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
//                                    ForEach(analyzedInstructions) { instruction in
//                                        VStack(alignment: .leading, spacing: 10) {
//                                            if !instruction.name.isEmpty {
//                                                Text(instruction.name)
//                                                    .font(.custom("ArialRoundedMTBold", size: 18))
//                                                    .foregroundColor(primaryColor)
//                                            }
//
//                                            ForEach(instruction.steps, id: \.number) { step in
//                                                StepView(step: step)
//                                            }
//                                        }
//                                        .padding(.bottom, 10)
//                                        .padding(.horizontal)
//                                    }
//                                } else if let instructions = recipe.instructions?.htmlDecoded(), !instructions.isEmpty {
//                                    Text(instructions)
//                                        .font(.custom("ArialRoundedMTBold", size: 18))
//                                        .padding(.horizontal)
//                                } else {
//                                    Text("No Instructions")
//                                        .foregroundColor(.gray)
//                                        .padding(.horizontal)
//                                }
//                            }
//                            if viewModel.isLoading {
//                                ProgressView()
//                                    .scaleEffect(1.5)
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                    .background(Color.orange.opacity(0.3))
//                                    .edgesIgnoringSafeArea(.all)
//                            }
//                        }
//                        .background(.white.opacity(0.6))
//                        .cornerRadius(30, corners: [.topLeft, .topRight])
//                    }
//                }
//                .onAppear {
//                    viewModel.getRecipeDetails(recipeId: recipeId)
//                }
//                .navigationBarTitle("Recipe Details", displayMode: .inline)
//                // 統一的 alert 修飾符
//                .alert(item: $activeAlert) { activeAlert in
//                    switch activeAlert {
//                    case .error(let errorMessage):
//                        return Alert(
//                            title: Text("Error"),
//                            message: Text(errorMessage.message),
//                            dismissButton: .default(Text("Sure")) {
//                                viewModel.errorMessage = nil
//                            }
//                        )
//                    case .ingredient(let message):
//                        return Alert(
//                            title: Text("Added to your Grocery List!"),
//                            message: Text(message),
//                            dismissButton: .default(Text("Sure"))
//                        )
//                    }
//                }
//            }
//        }
//    }
//
//    // 將更新份量的邏輯提取出來
//    private func updateServings() {
//        if let newServings = Int(inputServings), newServings > 0 {
//            viewModel.adjustServings(newServings: newServings)
//        } else {
//            activeAlert = .error(ErrorMessage(message: "Please insert a correct number."))
//        }
//    }
//
//    private func addIngredientToShoppingList(_ ingredient: ParsedIngredient) -> Bool {
//        let today = Calendar.current.startOfDay(for: Date())
//        let expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
//        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//
//        let newFoodItem = FoodItem(
//            name: ingredient.name.capitalized, // 每個單詞的首字母大寫
//            quantity: Int(Double(ingredient.quantity) ?? 1.0),
//            unit: ingredient.unit,
//            status: "Fridge", // 設置為「冷藏」
//            daysRemaining: 0, // 顯示今天
//            image: nil
//        )
//
//        if !foodItemStore.foodItems.contains(where: { $0.name.lowercased() == newFoodItem.name.lowercased() }) {
//            foodItemStore.foodItems.append(newFoodItem)
//            return true
//        } else {
//            return false
//        }
//    }
//}
//
//// 新增一個 CategoryItemView，用於顯示每個分類項目及其 TagViews
//struct CategoryItemView: View {
//    let title: String
//    let items: [String]
//    let primaryColor: Color
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 8) {
//            Text("•")
//                .font(.custom("ArialRoundedMTBold", size: 16))
//                .foregroundColor(primaryColor)
//
//            VStack(alignment: .leading, spacing: 5) {
//                Text("\(title):")
//                    .font(.custom("ArialRoundedMTBold", size: 16))
//                    .foregroundColor(.gray)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 8) {
//                        ForEach(items, id: \.self) { item in
//                            TagView(text: item)
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//// 新增一個 TagView，用於顯示每個項目
//struct TagView: View {
//    let text: String
//    
//    var body: some View {
//        Text(text)
//            .font(.custom("ArialRoundedMTBold", size: 15))
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.6))
//            .foregroundColor(.white)
//            .fontWeight(.medium)
//            .cornerRadius(8)
//    }
//}
//
//// 預覽
//struct RecipeDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeDetailView(recipeId: 1)
//            .environmentObject(RecipeSearchViewModel())
//            .environmentObject(FoodItemStore()) // 確保環境對象被傳遞
//    }
//}
