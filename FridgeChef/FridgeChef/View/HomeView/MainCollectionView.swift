//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//


import SwiftUI
import FirebaseAuth

struct MainCollectionView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var showingLogoutSheet = false
    @State private var showingNotificationSheet = false
    @State private var isEditing = false // 控制編輯模式狀態
    @State private var searchText = ""
    @State private var isShowingGameView = false
    @State private var showingRecipeSheet = false
    @State private var editingItem: FoodItem?
    @State private var selectedRecipe: Recipe?
    @State private var offsetX: CGFloat = -20
    @State private var isScaledUp = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                gradientBackground
                    .blur(radius: showingLogoutSheet || showingNotificationSheet ? 5 : 0)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {

                        // 新鮮食譜視圖
                        SectionTitleView(title: "⏰ Fridge Updates")
                            .padding(.horizontal)

                        FridgeReminderView(editingItem: $editingItem)

                        // Favorite Recipe 顯示區域
                        SectionTitleView(title: "📚 Favorite Recipe")
                            .padding(.horizontal)

                        // 搜索與篩選區域
                        SearchAndFilterView(searchText: $searchText)
                            .padding(.horizontal)
                        
                        // 使用子視圖 RecipeListView 來顯示篩選後的食譜列表
                        RecipeListView(selectedRecipe: $selectedRecipe, searchText: $searchText)
                            .sheet(item: $selectedRecipe, onDismiss: {
                                selectedRecipe = nil
                            }) { recipe in
                                if recipe.id == RecipeCollectionView_Previews.sampleRecipe.id {
                                    RecipeMainView()
                                } else {
                                    RecipeDetailView(recipeId: recipe.id)
                                }
                            }
                            .animation(nil) // 取消不必要的动画
                    }
                    .onAppear {
                        viewModel.loadFavorites()
                    }
                    .padding(.top)
                }
                .padding(.top, 20)
                .scrollIndicators(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        menuButton
                    }

                    ToolbarItem(placement: .principal) {
                        Image("FridgeChefLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 250, height: 180)
                            .padding(.top)
                    }

//                    ToolbarItem(placement: .navigationBarLeading) {
//                        notificationButton
//                    }
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                
                floatingButton
            }
            .onAppear {
                // Call loadFavorites() to load the user's favorite recipes from Firestore
                viewModel.loadFavorites()
            }
            .sheet(isPresented: $showingLogoutSheet) {
                LogoutSheetView()
                    .presentationDetents([.fraction(0.48)])
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingNotificationSheet) {
                ZStack {
                    gradientBackground
                        .edgesIgnoringSafeArea(.all)

                    notificationSheetContent
                }
                .presentationDetents([.fraction(0.48)])
            }
            .sheet(isPresented: $isShowingGameView) {
                WhatToEatGameView()
            }
        }
    }

    // 這些是您現有的其他 private views 和 functions
    private var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.yellow, Color.orange]),
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(0.4)
        .edgesIgnoringSafeArea(.all)
    }

    private var notificationButton: some View {
        Button(action: {
            showingNotificationSheet = true
        }) {
            Image(uiImage: UIImage(named: "bell") ?? UIImage(systemName: "bell.fill")!)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
        }
    }

    private var menuButton: some View {
        Button(action: {
            showingLogoutSheet = true
        }) {
            Image(uiImage: UIImage(named: "settling") ?? UIImage(systemName: "gearshape.fill")!)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.8))
        }
    }

    private var floatingButton: some View {
        ZStack {
            // Floating Button
            Button(action: {
                   isShowingGameView = true
               }) {
                   Image("clickmemonster")
                       .resizable()
                       .scaledToFit()
                       .frame(width: 130, height: 130)
                       .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
               }
               .padding(.trailing, -10)
               .padding(.top, 320)
               .scaleEffect(isScaledUp ? 1.0 : 0.8) // 根據狀態縮放
               .onAppear {
                   withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                       isScaledUp.toggle() // 切換縮放狀態
                   }
            }
        }
    }

    private var notificationSheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notification Summary")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .font(.custom("ZenLoop-Regular", size: 60))
                .padding(.top, 20)
                .frame(maxWidth: .infinity)

            Divider()
                .background(Color.orange)
                .padding(.horizontal)

            if expiringItemsCount > 0 {
                HStack {
                    Text("• ")
                        .foregroundColor(.primary)
                    Text("\(expiringItemsCount) items")
                        .foregroundColor(.blue)
                    Text(" expiring")
                        .foregroundColor(.primary)
                    Text(" within 3 days.")
                        .foregroundColor(.blue)
                }
                .fontWeight(.regular)
            }

            if expiredItemsCount > 0 {
                HStack {
                    Text("• ")
                        .foregroundColor(.primary)
                    Text("\(expiredItemsCount) items")
                        .foregroundColor(.red)
                    Text(" already")
                        .foregroundColor(.primary)
                    Text(" expired!")
                        .foregroundColor(.red)
                }
                .fontWeight(.bold)
            }
            Image("littlemonster")
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 200)
                .padding(.leading, 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clear)
        )
    }

    private var expiringItemsCount: Int {
        foodItemStore.foodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }.count
    }

    private var expiredItemsCount: Int {
        foodItemStore.foodItems.filter { $0.daysRemaining < 0 }.count
    }
}


struct MainCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MainCollectionView()
            .environmentObject(RecipeSearchViewModel())
            .environmentObject(FoodItemStore())
    }
}

//import SwiftUI
//import FirebaseAuth
//
//struct MainCollectionView: View {
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var showingLogoutSheet = false
//    @State private var showingNotificationSheet = false
//    @State private var isEditing = false // 控制編輯模式狀態
//    @State private var searchText = ""
//    @State private var isShowingGameView = false
//    @State private var editingItem: FoodItem?
//
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .topTrailing) { // 設置 ZStack 的對齊方式為 topTrailing
//                gradientBackground
//                    .blur(radius: showingLogoutSheet || showingNotificationSheet ? 5 : 0)
//
//                ScrollView {
//                    LazyVStack(alignment: .leading, spacing: 16) {
//                        // 標題文字
//                        Text("What would you like to cook today?")
//                            .padding(.horizontal)
//                            .foregroundColor(.orange)
////                            .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.systemOrange))
//                            .font(.custom("Menlo-BoldItalic", size: 25))
//                            .shadow(radius: 8)
//
//                        // 新鮮食譜視圖
//                        SectionTitleView(title: "⏰ Fridge Updates")
//                            .padding(.horizontal)
//
//                        FridgeReminderView(editingItem: $editingItem)
//                            .padding(.horizontal)
//
//                        SectionTitleView(title: "📚 Favorite Recipe")
//                            .padding(.horizontal)
//
//                        ForEach(viewModel.recipes.filter { $0.isFavorite }.isEmpty ? [RecipeCollectionView_Previews.sampleRecipe] : viewModel.recipes.filter { $0.isFavorite }) { recipe in
//                            NavigationLink(destination: recipe.id == RecipeCollectionView_Previews.sampleRecipe.id ? AnyView(RecipeMainView()) : AnyView(RecipeDetailView(recipeId: recipe.id))) {
//                                RecipeCollectionView(recipe: recipe, toggleFavorite: {
//                                    viewModel.toggleFavorite(for: recipe.id)
//                                })
//                                .padding(.horizontal)
//                                .padding(.vertical, 4)
//                            }
//                        }
//                        .onDelete(perform: deleteItems)
//                        .onMove(perform: moveItems)
//                    }
//                    .padding(.top)
//                }
//                .navigationBarTitleDisplayMode(.automatic)
//                .navigationTitle("Bonjour, Vicky🍻")/* Bonjour, Vicky 🍻 */
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        menuButton
//                    }
//
//                    ToolbarItem(placement: .principal) {
//                        Image("FridgeChefLogo")
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 250, height: 180)
//                            .padding(.top)
//                    }
//
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        notificationButton
//                    }
//                }
//                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
//
//                floatingButton
//            }
//            .sheet(isPresented: $showingLogoutSheet) {
//                LogoutSheetView()
//                    .presentationDetents([.fraction(0.48)])
//                    .edgesIgnoringSafeArea(.all)
//            }
//            .sheet(isPresented: $showingNotificationSheet) {
//                // Notification Sheet
//                ZStack {
//                    gradientBackground
//                        .edgesIgnoringSafeArea(.all)
//
//                    notificationSheetContent
//                }
//                .presentationDetents([.fraction(0.48)])
//            }
//            .sheet(isPresented: $isShowingGameView) {
//                WhatToEatGameView()
//            }
//        }
//        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search in collection")
//    }
//
//    private var gradientBackground: some View {
//        LinearGradient(
//            gradient: Gradient(colors: [Color.yellow, Color.orange]),
//            startPoint: .top,
//            endPoint: .bottom
//        )
//        .opacity(0.4)
//        .edgesIgnoringSafeArea(.all)
//    }
//
//    private var notificationButton: some View {
//        Button(action: {
//            showingNotificationSheet = true
//        }) {
//            Image(uiImage: UIImage(named: "bell") ?? UIImage(systemName: "bell.fill")!)
//                .resizable()
//                .frame(width: 24, height: 24) // 調整圖片大小
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//        }
//    }
//
//    private var menuButton: some View {
//        Button(action: {
//            showingLogoutSheet = true
//        }) {
////            Image(systemName: "gearshape")
//            Image(uiImage: UIImage(named: "settling") ?? UIImage(systemName: "gearshape.fill")!)
//                .resizable()
//                .frame(width: 24, height: 24) // 調整圖片大小
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.8))
//        }
//    }
//
//    private var notificationSheetContent: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text("Notification Summary")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .font(.custom("ZenLoop-Regular", size: 60))
//                .padding(.top, 5)
//                .frame(maxWidth: .infinity)
//
//            Divider()
//                .background(Color.orange)
//                .padding(.horizontal)
//
//            if expiringItemsCount > 0 {
//                HStack {
//                    Text("• ")
//                        .foregroundColor(.primary)
//                    Text("\(expiringItemsCount) items")
//                        .foregroundColor(.blue)
//                    Text(" expiring")
//                        .foregroundColor(.primary)
//                    Text(" within 3 days.")
//                        .foregroundColor(.blue)
//                }
//                .fontWeight(.regular)
//            }
//
//            if expiredItemsCount > 0 {
//                HStack {
//                    Text("• ")
//                        .foregroundColor(.primary)
//                    Text("\(expiredItemsCount) items")
//                        .foregroundColor(.red)
//                    Text(" already")
//                        .foregroundColor(.primary)
//                    Text(" expired!")
//                        .foregroundColor(.red)
//                }
//                .fontWeight(.bold)
//            }
//            Image("littlemonster")
//                .resizable()
//                .scaledToFill()
//                .frame(width: 200, height: 200)
//                .padding(.leading, 180)
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.clear)
//        )
//    }
//
//    private var floatingButton: some View {
//        Button(action: {
//            isShowingGameView = true
//        }) {
//            Image("himonster")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 120, height: 120)
//                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 10)
//        }
//        .padding(.trailing, -10)
//        .padding(.top, 40)
//    }
//
//    private func logOut() {
//        try? Auth.auth().signOut()
//        UserDefaults.standard.set(false, forKey: "log_Status") // 確保 log_Status 已正確更新
//    }
//
//    private func deleteAccount() {
//        // 在此處添加 Firebase 或其他後端的帳戶刪除邏輯
//        // 例如：
//        // Auth.auth().currentUser?.delete { error in
//        //     if let error = error {
//        //         // 處理錯誤
//        //     } else {
//        //         // 刪除成功，更新 UI 或導航
//        //     }
//        // }
//    }
//
//    private func deleteItems(at offsets: IndexSet) {
//        withAnimation {
//            viewModel.recipes.remove(atOffsets: offsets)
//        }
//    }
//
//    private func moveItems(from source: IndexSet, to destination: Int) {
//        withAnimation {
//            viewModel.recipes.move(fromOffsets: source, toOffset: destination)
//        }
//    }
//
//    private var expiringItemsCount: Int {
//        foodItemStore.foodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }.count
//    }
//
//    private var expiredItemsCount: Int {
//        foodItemStore.foodItems.filter { $0.daysRemaining < 0 }.count
//    }
//}
//
//struct MainCollectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainCollectionView()
//            .environmentObject(RecipeSearchViewModel())
//            .environmentObject(FoodItemStore())
//    }
//}
