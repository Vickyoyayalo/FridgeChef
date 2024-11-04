//
//  MainCollectionView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/30.
//

import SwiftUI
import FirebaseAuth

struct MainCollectionView: View {
    @ObservedObject var viewModel: RecipeSearchViewModel
    @ObservedObject var foodItemStore: FoodItemStore
    @State private var showingLogoutSheet = false
    @State private var showingNotificationSheet = false
    @State private var isEditing = false
    @State private var searchText = ""
    @State private var isShowingGameView = false
    @State private var showingRecipeSheet = false
    @State private var editingItem: FoodItem?
    @State private var selectedRecipe: Recipe?
    @State private var isScaledUp = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                gradientBackground
                    .blur(radius: showingLogoutSheet || showingNotificationSheet ? 5 : 0)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        
                        SectionTitleView(title: "⏰ Fridge Updates")
                            .padding(.horizontal)
                        
                        FridgeReminderView(foodItemStore: foodItemStore, editingItem: $editingItem)
                        
                        SectionTitleView(title: "📚 Favorite Recipe")
                            .padding(.horizontal)
                        
                        SearchAndFilterView(searchText: $searchText)
                            .padding(.horizontal)
                        
                        RecipeListView(
                            viewModel: viewModel,
                            selectedRecipe: $selectedRecipe,
                            searchText: $searchText
                        )
                        .sheet(item: $selectedRecipe, onDismiss: {
                            selectedRecipe = nil
                        }) { recipe in
                            if recipe.id == RecipeCollectionView_Previews.sampleRecipe.id {
                                RecipeMainView(viewModel: viewModel, foodItemStore: foodItemStore)
                            } else {
                                RecipeDetailView(recipeId: recipe.id, viewModel: viewModel, foodItemStore: foodItemStore)
                            }
                        }
                    }
                    .onAppear {
                        viewModel.loadFavorites()
                    }
                    .padding(.top)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 20)
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
                }
                .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                
                floatingButton
            }
            .onAppear {
                viewModel.loadFavorites()
            }
            .sheet(isPresented: $showingLogoutSheet) {
                LogoutSheetView()
                    .presentationDetents([.fraction(0.55)])
                    .edgesIgnoringSafeArea(.all)
            }
            .sheet(isPresented: $showingNotificationSheet) {
                ZStack {
                    gradientBackground
                        .edgesIgnoringSafeArea(.all)
                    
                    notificationSheetContent
                }
                .presentationDetents([.fraction(0.55)])
            }
            .sheet(isPresented: $isShowingGameView) {
                WhatToEatGameView()
            }
        }
    }
    
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
            .scaleEffect(isScaledUp ? 1.0 : 0.8)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isScaledUp.toggle()
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
        MainCollectionView(
            viewModel: RecipeSearchViewModel(),
            foodItemStore: FoodItemStore())
    }
}
