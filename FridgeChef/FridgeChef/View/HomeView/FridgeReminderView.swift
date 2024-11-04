//
//  FreshRecipesView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/05.
//

import SwiftUI
import SDWebImageSwiftUI

struct FridgeReminderView: View {
    @ObservedObject var foodItemStore: FoodItemStore
    @Binding var editingItem: FoodItem?
    @State private var selectedFoodItem: FoodItem? 
    @State private var showingSheet = false

    private var expiringItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.status != .toBuy && $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }
    }

    private var expiredItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.status != .toBuy && $0.daysRemaining < 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if expiringItems.isEmpty {
                        DefaultFridgeReminderCard(color: .blue.opacity(0.2), message: "No items will expire within 3 days.", textColor: .blue)
                    }

                    if expiredItems.isEmpty {
                        DefaultFridgeReminderCard(color: .red.opacity(0.2), message: "No items expired.", textColor: .red)
                    }

                    ForEach(expiringItems) { item in
                        Button(action: {
                            selectedFoodItem = item
                            showingSheet = true
                        }) {
                            FridgeRecipeCard(foodItem: item, isExpired: false)
                        }
                    }

                    ForEach(expiredItems) { item in
                        Button(action: {
                            selectedFoodItem = item
                            showingSheet = true
                        }) {
                            FridgeRecipeCard(foodItem: item, isExpired: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
        }
        .padding(.horizontal)

        .sheet(item: $selectedFoodItem) { foodItem in
            if foodItem.status == .toBuy {
                GroceryListView(foodItemStore: FoodItemStore())
            } else {
                FridgeView(foodItemStore: FoodItemStore())
            }
        }
    }
}

struct DefaultFridgeReminderCard: View {
    let color: Color
    let message: String
    let textColor: Color
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
               
                Image("FridgeUpdate")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .cornerRadius(10)
                    .clipped()
                    .shadow(radius: 5)
              
                Text(message)
                    .fontWeight(.medium)
                    .font(.custom("ArialRoundedMTBold", size: 14))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, maxHeight: 40)
                    .padding(.top, 8)
                
            }
            .padding()
            .background(color)
            .cornerRadius(20.0)
            .shadow(radius: 8)
        }
        .frame(width: 180, height: 250)
    }
}

struct FridgeRecipeCard: View {
    let foodItem: FoodItem
    let isExpired: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                
                if let imageURLString = foodItem.imageURL, let imageURL = URL(string: imageURLString) {
                    WebImage(url: imageURL)
                        .resizable()
                        .background(
                            Image("RecipeFood")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                        )
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .opacity(0.8)
                        )
                        .transition(.opacity)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity)
                } else {
                    Image("RecipeFood")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity)
                }

                Text(foodItem.name)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(foodItem.quantity, specifier: "%.1f") \(foodItem.unit)")
                    .font(.custom("ArialRoundedMTBold", size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                if isExpired {
                    Text("Expired \n\(abs(foodItem.daysRemaining)) days ago‼️")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else if foodItem.daysRemaining == 0 {
                    Text("It's TODAY 🍳")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(.purple)
                        .multilineTextAlignment(.center)
                        .fontWeight(.bold)
                } else {
                    Text("⚠️ \(foodItem.daysRemaining) days \nRemaining")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(isExpired ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(20.0)
        }
        .frame(width: 180, height: 250)
        .padding(.trailing, 10)
    }
}


struct FridgeReminderView_Preview: PreviewProvider {
    @State static var editingItem: FoodItem? = nil

    static var previews: some View {
        FridgeReminderView(foodItemStore: FoodItemStore(), editingItem: $editingItem)
            .environmentObject(FoodItemStore())
    }
}
